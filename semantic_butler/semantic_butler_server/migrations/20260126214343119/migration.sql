BEGIN;

--
-- CREATE PG_TRGM EXTENSION IF AVAILABLE
--
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'pg_trgm') THEN
    EXECUTE 'CREATE EXTENSION IF NOT EXISTS pg_trgm';
  END IF;
END
$$;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "file_index" ADD COLUMN IF NOT EXISTS "pageCount" bigint;
CREATE INDEX IF NOT EXISTS "idx_file_index_filename_trgm" ON "file_index" USING gin ("fileName" gin_trgm_ops);
CREATE INDEX IF NOT EXISTS "idx_file_index_content_preview_trgm" ON "file_index" USING gin ("contentPreview" gin_trgm_ops);

--
-- MIGRATION VERSION FOR semantic_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20260126214343119', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260126214343119', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
