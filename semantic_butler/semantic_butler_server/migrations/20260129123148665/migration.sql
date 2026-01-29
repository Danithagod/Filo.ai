BEGIN;

--
-- ACTION ALTER TABLE
--
DROP INDEX "file_index_content_hash";
CREATE INDEX "file_index_content_hash" ON "file_index" USING btree ("contentHash");

--
-- MIGRATION VERSION FOR semantic_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20260129123148665', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129123148665', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
