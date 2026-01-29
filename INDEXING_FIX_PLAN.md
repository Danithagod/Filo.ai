[x] **Phase 1: Parity & Cost Controls (Quick Wins)**
    - [x] Extraction Parity in Flutter (PDF/DOCX)
    - [x] Hash Verification (Pre-check)
    - [x] Configurability (API Key guards)

[x] **Phase 2: Depth & Performance**
    - [x] Multi-Chunking Implementation (Sliding Window)
    - [x] Concurrency & Throughput (FutureGroup workers)
    - [x] Refined Filtering

[x] **Phase 3: Observability & Recovery**
    - [x] Per-file Diagnostics (Detailed Modal)
    - [x] Heartbeat & Recovery (Checkpoints)
    - [x] UX Polish (Real-time counters)

## Implementation Notes
- **Source of Truth**: The Backend `FileExtractionService` remains the source of truth for file support.
- **Protocol**: The `uploadIndex` contract must be verified for 1-to-N (File-to-Embeddings) mapping.
- **Tests**: Chunker unit tests and Hash-skip integration tests are mandatory.
