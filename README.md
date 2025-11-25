# Project Mimi: The Sovereign Custody Engine

**Status:** Code Complete (Phase 2) | **Role:** Principal Architect | **Thesis:** [Live Fire Defense](./scripts/thesis_defense.sh)

## 1. Executive Summary
Project Mimi is a **Hardware-Augmented MPC Custody System** designed to eliminate the "Superuser Risk" inherent in cloud-based wallets. Unlike traditional MPC, which relies on software-based policy enforcement, Mimi enforces security invariants using **Physical Physics (JCOP)**, **Confidential Computing (Nitro Enclaves)**, and **Kernel-Level Kinetic Authorization (eBPF)**.

This repository contains the **Core Engine** (Rust/Solidity/C++/eBPF) and the **Formal Proofs** of the architecture.

---

## 2. The Security Invariants (L6 Signal)

The architecture is defined by 7 non-negotiable invariants. If any invariant is violated, the system Fails-Closed.

| Invariant | Component | Implementation | Evidence Artifact |
| :--- | :--- | :--- | :--- |
| **Inv 1: Supply Chain** | Build Pipeline | **Reproducible Builds** (Bit-for-bit determinism) | [`audit_manifest.json`](./evidence/l6_artifacts/audit_manifest.json) |
| **Inv 2: Identity** | Policy Engine | **Bound Attestation** (PCR0 locking KMS) | [`master_key_policy.json`](./infra/kms/master_key_policy.json) |
| **Inv 3: Anti-Rollback** | Enclave | **State Continuity** via Scroll L2 Anchor | [`ChronosGuardAnchor.sol`](./contracts/ChronosGuardAnchor.sol) |
| **Inv 4: Authorization** | Network | **Kinetic Firewall** (eBPF XDP Drop-All) | [`kinetic_dropper.c`](./network/ebpf/kinetic_dropper.c) |
| **Inv 5: Privacy** | Infrastructure | **Zero-Log RAM Boot** (iPXE + stboot) | [`ipxe.conf`](./infra/boot/ipxe.conf) |
| **Inv 6: Recovery** | Smart Contract | **Dead Man's Switch** (365-day Time-Lock) | [`AnchorTest.cjs`](./test/AnchorTest.cjs) |
| **Inv 7: Determinism** | Hardware (JCOP) | **Atomic "Delete-First" Protocol** | [`DeleteFirstApplet.java`](./src/main/java/com/mimi/jcop/DeleteFirstApplet.java) |

---

## 3. Architecture & Performance

### The Hybrid Commit-and-Prove Model
To achieve consumer-grade latency (<1s) on constrained hardware, Mimi offloads ZK proof generation while maintaining hardware sovereignty.

* **Layer 1 (Card):** NXP JCOP 5 (Java Card 3.1). Acts as "Signer-of-Witness".
* **Layer 2 (Net):** AmneziaWG + Rosenpass (Post-Quantum Rotator).
* **Layer 3 (Client):** C++ Rapidsnark Prover via JSI.

**Performance Benchmark:**
> **ZK Proof Generation:** `63ms` (100M constraint simulation)
> **Protocol Verification:** `0 Failures` (Verifpal Formal Analysis)

---

## 4. Live Fire Defense (Replication)

To verify the entire stack (Java Card $\to$ Rust Enclave $\to$ Solidity Anchor), execute the defense script:

```bash
./scripts/thesis_defense.sh
```

**Expected Output:**
```text
[1/7] PROTOCOL SECURITY ... PASS
[2/7] HARDWARE PHYSICS .... PASS
[3/7] ANTI-ROLLBACK ....... PASS
[4/7] ZK LATENCY .......... PASS
[5/7] KINETIC AUTH ........ PASS
[6/7] ZERO-LOG INFRA ...... PASS
[7/7] SUPPLY CHAIN ........ PASS

ALL SYSTEMS NOMINAL. THESIS PROVEN.
```

---

## 5. Directory Structure

* **`/src/enclave`**: Rust logic for the TEE (Policy Engine).
* **`/native/prover`**: C++ bindings for the ZK acceleration.
* **`/network/ebpf`**: Kernel-space XDP firewall code.
* **`/contracts`**: Solidity anchors for L2 state continuity.
* **`/evidence`**: Formal models (Verifpal) and Audit Manifests.

