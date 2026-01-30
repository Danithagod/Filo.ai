BEGIN;

--
-- ACTION ALTER TABLE
--
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "document_embedding"
    ADD CONSTRAINT "document_embedding_fk_0"
    FOREIGN KEY("fileIndexId")
    REFERENCES "file_index"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR semantic_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20260130135236185', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260130135236185', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
