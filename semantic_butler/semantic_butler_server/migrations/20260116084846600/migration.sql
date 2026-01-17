BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "tag_taxonomy" (
    "id" bigserial PRIMARY KEY,
    "category" text NOT NULL,
    "tagValue" text NOT NULL,
    "frequency" bigint NOT NULL,
    "firstSeenAt" timestamp without time zone NOT NULL,
    "lastSeenAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "tag_taxonomy_category_idx" ON "tag_taxonomy" USING btree ("category");
CREATE INDEX "tag_taxonomy_value_idx" ON "tag_taxonomy" USING btree ("tagValue");
CREATE INDEX "tag_taxonomy_frequency_idx" ON "tag_taxonomy" USING btree ("frequency");


--
-- MIGRATION VERSION FOR semantic_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20260116084846600', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260116084846600', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
