-- Fix the embedding column type from text to vector
-- This script should be run manually against the database

-- Step 1: Drop the old btree index on the text column
DROP INDEX IF EXISTS idx_document_embedding_hnsw CASCADE;

-- Step 2: Drop the old text column (backup data first using embeddingJson)
-- We'll recreate the vector column from embeddingJson

-- Step 3: Add the new vector column (temporary name)
ALTER TABLE document_embedding ADD COLUMN IF NOT EXISTS embedding_vector_new vector(768);

-- Step 4: Migrate data from embeddingJson to the new vector column
UPDATE document_embedding
SET embedding_vector_new = embedding_json::vector(768)
WHERE embedding_json IS NOT NULL;

-- Step 5: Drop the old text column
ALTER TABLE document_embedding DROP COLUMN IF EXISTS embedding;

-- Step 6: Rename the new vector column to embedding
ALTER TABLE document_embedding RENAME COLUMN embedding_vector_new TO embedding;

-- Step 7: Make the column nullable (as per model definition)
ALTER TABLE document_embedding ALTER COLUMN embedding DROP NOT NULL;

-- Step 8: Create the HNSW index for vector similarity search
CREATE INDEX idx_document_embedding_hnsw ON document_embedding
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Step 9: Update the migration registry
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20260121183056295', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260121183056295', "timestamp" = now();
