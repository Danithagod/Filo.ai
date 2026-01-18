BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "indexing_job" ADD COLUMN "errorCategory" text;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "indexing_job_detail" ADD COLUMN "errorCategory" text;
CREATE INDEX "idx_job_detail_error_category" ON "indexing_job_detail" USING btree ("errorCategory");

-- Install pgvector extension if not exists
CREATE EXTENSION IF NOT EXISTS vector;

-- Add vector column to document_embedding table
ALTER TABLE document_embedding 
ADD COLUMN IF NOT EXISTS embedding vector(768);

-- Populate from existing embeddingJson column
-- Only migrate embeddings that match the target dimension (768)
UPDATE document_embedding 
SET embedding = "embeddingJson"::vector
WHERE embedding IS NULL 
  AND "embeddingJson" IS NOT NULL 
  AND json_array_length("embeddingJson"::json) = 768;

-- Create IVFFlat index (standard index, CONCURRENTLY not allowed in transaction block)
-- CREATE INDEX IF NOT EXISTS idx_embedding_vector_ivfflat
-- ON document_embedding
-- USING ivfflat (embedding vector_cosine_ops)
-- WITH (lists = 100);

-- Update statistics
ANALYZE document_embedding;

--
-- MIGRATION VERSION FOR semantic_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20260117221944913', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260117221944913', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
