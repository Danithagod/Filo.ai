BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "saved_search_preset" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "query" text NOT NULL,
    "category" text,
    "tags" json,
    "fileTypes" json,
    "dateFrom" timestamp without time zone,
    "dateTo" timestamp without time zone,
    "minSize" bigint,
    "maxSize" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "usageCount" bigint NOT NULL
);

--
-- ACTION ALTER TABLE
--
ALTER TABLE "search_history" ADD COLUMN "searchType" text;
ALTER TABLE "search_history" ADD COLUMN "directoryContext" text;
CREATE INDEX "search_history_type" ON "search_history" USING btree ("searchType");

--
-- MIGRATION VERSION FOR semantic_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20260118163519353', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260118163519353', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
