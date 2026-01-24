BEGIN;

--
-- ACTION ALTER TABLE
--
-- ALTER TABLE "document_embedding" ADD COLUMN "embedding" text;
-- CREATE INDEX "idx_document_embedding_hnsw" ON "document_embedding" USING btree ("embedding");

--
-- MIGRATION VERSION FOR semantic_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20260121183056295', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260121183056295', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
