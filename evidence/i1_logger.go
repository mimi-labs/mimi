package evidence

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/google/uuid"
)

type I1Event struct {
	EventID                  string                 `json:"event_id"`
	TimestampUTC             string                 `json:"timestamp_utc"`
	ActorType                string                 `json:"actor_type"`
	ActorID                  string                 `json:"actor_id"`
	EventType                string                 `json:"event_type"`
	Decision                 string                 `json:"decision"`
	ReasonCodes              []string               `json:"reason_codes,omitempty"`
	PolicyHash               string                 `json:"policy_hash,omitempty"`
	CorrelationID            string                 `json:"correlation_id,omitempty"`
	Metadata                 map[string]interface{} `json:"metadata,omitempty"`
	K8sObject                string                 `json:"k8s_object,omitempty"`
	ImageRef                 string                 `json:"image_ref,omitempty"`
	KyvernoPolicy            string                 `json:"kyverno_policy,omitempty"`
	CosignVerificationResult string                 `json:"cosign_verification_result,omitempty"`
	DemoStep                 string                 `json:"demo_step,omitempty"`
}

func NewI1Event(base I1Event) I1Event {
	if base.EventID == "" {
		base.EventID = uuid.NewString()
	}
	if base.TimestampUTC == "" {
		base.TimestampUTC = time.Now().UTC().Format(time.RFC3339Nano)
	}
	return base
}

func AppendI1Event(path string, e I1Event) error {
	e = NewI1Event(e)

	f, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
	if err != nil {
		return fmt.Errorf("open evidence file: %w", err)
	}
	defer f.Close()

	enc := json.NewEncoder(f)
	if err := enc.Encode(e); err != nil {
		return fmt.Errorf("encode event: %w", err)
	}
	return nil
}
