BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "document_embedding" (
    "id" bigserial PRIMARY KEY,
    "fileIndexId" bigint NOT NULL,
    "chunkIndex" bigint NOT NULL,
    "chunkText" text,
    "embeddingJson" text NOT NULL,
    "dimensions" bigint NOT NULL
);

-- Indexes
CREATE INDEX "document_embedding_file_index" ON "document_embedding" USING btree ("fileIndexId");
CREATE UNIQUE INDEX "document_embedding_file_chunk" ON "document_embedding" USING btree ("fileIndexId", "chunkIndex");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "file_index" (
    "id" bigserial PRIMARY KEY,
    "path" text NOT NULL,
    "fileName" text NOT NULL,
    "contentHash" text NOT NULL,
    "fileSizeBytes" bigint NOT NULL,
    "mimeType" text,
    "contentPreview" text,
    "tagsJson" text,
    "status" text NOT NULL,
    "errorMessage" text,
    "embeddingModel" text,
    "indexedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "file_index_path_unique" ON "file_index" USING btree ("path");
CREATE INDEX "file_index_content_hash" ON "file_index" USING btree ("contentHash");
CREATE INDEX "file_index_status" ON "file_index" USING btree ("status");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "indexing_job" (
    "id" bigserial PRIMARY KEY,
    "folderPath" text NOT NULL,
    "status" text NOT NULL,
    "totalFiles" bigint NOT NULL,
    "processedFiles" bigint NOT NULL,
    "failedFiles" bigint NOT NULL,
    "skippedFiles" bigint NOT NULL,
    "startedAt" timestamp without time zone,
    "completedAt" timestamp without time zone,
    "errorMessage" text
);

-- Indexes
CREATE INDEX "indexing_job_status" ON "indexing_job" USING btree ("status");
CREATE INDEX "indexing_job_folder" ON "indexing_job" USING btree ("folderPath");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "search_history" (
    "id" bigserial PRIMARY KEY,
    "query" text NOT NULL,
    "resultCount" bigint NOT NULL,
    "topResultId" bigint,
    "queryTimeMs" bigint NOT NULL,
    "searchedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "search_history_queried_at" ON "search_history" USING btree ("searchedAt");


--
-- MIGRATION VERSION FOR semantic_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20251217202628604', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251217202628604', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20251208110420531-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110420531-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20251208110412389-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110412389-v3-0-0', "timestamp" = now();


COMMIT;
