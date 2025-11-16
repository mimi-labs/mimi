package main

import (
    "flag"
    "log"
    "os"

    "prufwerk/evidence"
)

func main() {
    var (
        outPath   string
        eventType string
        decision  string
        imageRef  string
        demoStep  string
    )

    flag.StringVar(&outPath, "out", "evidence/logs/i1/demo_i1_events.jsonl", "output JSONL path")
    flag.StringVar(&eventType, "event_type", "ADMISSION_DECISION", "event type")
    flag.StringVar(&decision, "decision", "", "decision: ALLOW or DENY")
    flag.StringVar(&imageRef, "image_ref", "", "container image ref")
    flag.StringVar(&demoStep, "demo_step", "", "demo step label")
    flag.Parse()

    if decision == "" {
        log.Println("decision is required (ALLOW or DENY)")
        os.Exit(1)
    }

    evt := evidence.I1Event{
        ActorType: "system",
        ActorID:   "i1log-cli",

        EventType: eventType,
        Decision:  decision,

        ImageRef: imageRef,
        DemoStep: demoStep,
    }

    if err := evidence.AppendI1Event(outPath, evt); err != nil {
        log.Fatalf("append event: %v", err)
    }
}
