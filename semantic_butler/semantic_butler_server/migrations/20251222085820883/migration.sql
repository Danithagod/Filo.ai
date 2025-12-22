BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "watched_folders" (
    "id" bigserial PRIMARY KEY,
    "path" text NOT NULL,
    "isEnabled" boolean NOT NULL,
    "lastEventAt" timestamp without time zone,
    "filesWatched" bigint
);


--
-- MIGRATION VERSION FOR semantic_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20251222085820883', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251222085820883', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
