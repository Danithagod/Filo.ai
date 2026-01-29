BEGIN;

--
-- CREATE VECTOR EXTENSION IF AVAILABLE
--
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'vector') THEN
    EXECUTE 'CREATE EXTENSION IF NOT EXISTS vector';
  ELSE
    RAISE EXCEPTION 'Required extension "vector" is not available on this instance. Please install pgvector. For instructions, see https://docs.serverpod.dev/upgrading/upgrade-to-pgvector.';
  END IF;
END
$$;

--
-- ACTION DROP TABLE
--
DROP TABLE "document_embedding" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "document_embedding" (
    "id" bigserial PRIMARY KEY,
    "fileIndexId" bigint NOT NULL,
    "chunkIndex" bigint NOT NULL,
    "chunkText" text,
    "embedding" vector(768) NOT NULL,
    "embeddingJson" text,
    "dimensions" bigint
);

-- Indexes
CREATE INDEX "document_embedding_file_index" ON "document_embedding" USING btree ("fileIndexId");
CREATE UNIQUE INDEX "document_embedding_file_chunk" ON "document_embedding" USING btree ("fileIndexId", "chunkIndex");
CREATE INDEX "document_embedding_vector_hnsw" ON "document_embedding" USING hnsw ("embedding" vector_cosine_ops);

--
-- ACTION ALTER TABLE
--
DROP INDEX "file_index_content_hash";
CREATE UNIQUE INDEX "file_index_content_hash" ON "file_index" USING btree ("contentHash");

--
-- MIGRATION VERSION FOR semantic_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20260125151255224', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260125151255224', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
