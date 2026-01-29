# Indexing Feature: Deep Analysis & Remediation Plan (Jan 29, 2026)

## Current Architecture

- **Hybrid flow**: Flutter client extracts text and calls OpenRouter for embeddings, then uploads `FileIndex` + `DocumentEmbedding` to Serverpod backend via `indexing.uploadIndex` @semantic_butler_flutter/lib/services/local_indexing_service.dart#21-63 @semantic_butler_server/lib/src/endpoints/indexing_endpoint.dart#8-80.
- **Backend persistence**: `FileIndex` records metadata/hash; `DocumentEmbedding` stores vectors with `chunkIndex`, allowing multi-chunk per file @semantic_butler_server/lib/src/generated/file_index.dart#15-93 @semantic_butler_server/lib/src/generated/document_embedding.dart#15-49.
- **Job tracking**: Client registers and updates `IndexingJob` aggregates; per-file detail table `indexing_job_detail` exists but is unused by client @semantic_butler_flutter/lib/services/local_indexing_service.dart#109-170 @semantic_butler_client/lib/src/protocol/indexing_job_detail.dart#15-82.

## Gap Analysis

1) **Extraction Parity (Critical)**
   - Frontend extraction is a simplified port: plain `readAsString`, no PDF/DOCX handling, no media/archive metadata, fixed mime/category @semantic_butler_flutter/lib/services/local_indexing_service.dart#179-211.
   - Backend supports broad extensions, classification (code/config/data/document/media), mime mapping, and PDF/media/archive handling @semantic_butler_server/lib/src/services/file_extraction_service.dart#15-258.
   - Impact: PDFs/code/config files are misclassified or skipped; metadata richness is lost.

2) **Chunking & Coverage (High)**
   - Frontend truncates to first 8k chars and emits a single chunk @semantic_butler_flutter/lib/services/local_indexing_service.dart#195-207.
   - Schema supports multiple chunks via `chunkIndex`, but client never uses it @semantic_butler_server/lib/src/generated/document_embedding.dart#20-44.
   - Impact: Large documents are partially indexed; semantic search misses tail content.

3) **Redundant Embedding Costs (Economic/Perf)**
   - Frontend always embeds; no pre-check against server hashes despite computing `contentHash` @semantic_butler_flutter/lib/services/local_indexing_service.dart#200-211.
   - Backend lacks a `checkHash` endpoint to short-circuit duplicates @semantic_butler_server/lib/src/endpoints/indexing_endpoint.dart#8-80.
   - Impact: Re-embedding unchanged files increases cost/latency.

4) **Observability Gaps (UX/Support)**
   - Client only updates aggregate job counts; no writes to `indexing_job_detail` @semantic_butler_flutter/lib/services/local_indexing_service.dart#109-170.
   - Users cannot see which files failed or why; backend schema for details is unused @semantic_butler_client/lib/src/protocol/indexing_job_detail.dart#15-82.

5) **Throughput Bottleneck (Perf)**
   - Directory processing is strictly serial; no worker pool @semantic_butler_flutter/lib/services/local_indexing_service.dart#126-154.
   - Impact: Large folders take longer than necessary; backend can handle more parallelism.

6) **Resilience / Ghost Jobs (Reliability)**
   - If the app crashes mid-run, jobs remain `running`; no heartbeat or recovery sweep @semantic_butler_flutter/lib/services/local_indexing_service.dart#109-170.
   - Impact: Stale state in UI/backend; user confusion.

7) **Filtering Parity**
   - Client skips hidden files via path check, but does not honor backend ignore patterns (`matchesIgnorePattern` not mirrored) @semantic_butler_flutter/lib/services/local_indexing_service.dart#81-96.
   - Impact: Potentially indexes files the backend would ignore (noise) or misses rules.

## Remediation Plan (Expanded)

### Phase 1: Parity & Cost Controls

- Port frontend extraction to mirror backend: supported extensions, category detection, mime map; add basic PDF text extraction; metadata-only for media/archives.
- Add `checkHash(contentHash)` endpoint (backend) and client pre-check to skip unchanged files; count as "skipped".
- Gate OpenRouter calls on API key; fail fast with UI error; keep 8k guard temporarily.

### Phase 2: Depth & Performance

- Implement sliding-window chunker (e.g., 2000 chars, 200 overlap); emit multiple `DocumentEmbedding` entries with `chunkIndex`.
- Add bounded concurrency (pool 3–5) for indexing; throttle backend updates.
- Apply refined filtering: honor `.gitignore`/ignore patterns like backend.

### Phase 3: Observability & Recovery

- Write per-file results to `indexing_job_detail` (status, started/completed, errorCategory/message); surface failed list in UI.
- Heartbeat during long runs; on startup, detect client-owned `running` jobs and mark as interrupted or resume.
- UX: live counters for processed/failed/skipped; clear error surfaces for missing API key, unsupported file, PDF parse, embedding failure.

## Test & Contract Notes

- Verify `uploadIndex` supports 1:N (FileIndex to multiple DocumentEmbeddings); adjust endpoint or add batch variant if needed.
- Add unit tests: chunker coverage; hash-skip flow; job detail write/read; recovery path.
- Integration: golden path for PDF/Docx/code file extraction vs backend classification.
