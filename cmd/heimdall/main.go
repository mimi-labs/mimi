package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/mdlayher/vsock"
)

// Configuration Constants (L7 Mandates)
const (
	EnclavePort = 5000
	EnclaveCID  = 16                     // Well-known CID for the first Nitro Enclave
	AuthHeader  = "X-Mimi-Kinetic-Token" // Invariant 4: Kinetic Auth
)

// SigningRequest is the opaque payload from the Mobile Client (Zone A)
type SigningRequest struct {
	EncryptedPayload string `json:"payload" binding:"required"`
	ClientVersion    string `json:"client_ver" binding:"required"` // Plan F: 3.B.7
}

func main() {
	// 1. Setup Zero-Log Router (Invariant 5)
	// We force ReleaseMode to suppress debug logs in production
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())

	// 2. The Kinetic Auth Middleware (Plan F: Step 3.A.4)
	// This enforces the "Drop-All" policy at the application layer.
	// In the future, this logic moves to eBPF (dropper.c).
	r.Use(func(c *gin.Context) {
		token := c.GetHeader(AuthHeader)
		if token == "" {
			// Silent Drop (401)
			c.AbortWithStatusJSON(401, gin.H{"error": "Kinetic Drop: Token Required"})
			return
		}
		c.Next()
	})

	// 3. The Vault Interface
	r.POST("/v1/vault/sign", func(c *gin.Context) {
		var req SigningRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "Protocol Violation"})
			return
		}

		// 4. Bridge to Enclave (The "Air Gap" Crossing)
		response, err := bridgeToEnclave(req)
		if err != nil {
			log.Printf("Enclave Bridge Error: %v", err)
			c.JSON(502, gin.H{"error": "Vault Unreachable"})
			return
		}

		c.Data(200, "application/json", response)
	})

	log.Println("Heimdall Gateway Online: Listening on :8080")
	r.Run(":8080")
}

// bridgeToEnclave handles the transport switching (VSOCK vs TCP)
func bridgeToEnclave(req SigningRequest) ([]byte, error) {
	payload, _ := json.Marshal(req)
	var conn net.Conn
	var err error

	// STRATEGY: Try VSOCK (Real Enclave) first. If it fails, fallback to TCP (Mock).
	// This allows the same code to run on your $6 VPS and the $120 AWS Nitro.

	// FIX APPLIED: Added 'nil' as the 3rd argument for vsock.Dial
	conn, err = vsock.Dial(EnclaveCID, EnclavePort, nil)
	if err != nil {
		// FALLBACK: Development Mode (Docker Mock)
		// This saves you $120/mo during Dev
		log.Println("VSOCK unavailable, falling back to TCP Mock...")
		conn, err = net.Dial("tcp", "127.0.0.1:5000")
		if err != nil {
			return nil, fmt.Errorf("connection failed: %w", err)
		}
	}
	defer conn.Close()

	// Invariant 7: Atomic Determinism (Timeouts)
	conn.SetDeadline(time.Now().Add(2 * time.Second))

	// Send Data
	if _, err := conn.Write(payload); err != nil {
		return nil, err
	}

	// Read Response
	var buf bytes.Buffer
	if _, err := io.Copy(&buf, conn); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}
