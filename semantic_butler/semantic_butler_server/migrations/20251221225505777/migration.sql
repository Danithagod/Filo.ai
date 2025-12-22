BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_core_user" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_core_session" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_core_profile_image" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_core_profile" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_core_jwt_refresh_token" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_secret_challenge" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_rate_limited_request_attempt" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_passkey_challenge" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_passkey_account" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_google_account" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_email_account_request" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_email_account_password_reset_request" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_email_account" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_idp_apple_account" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "agent_file_command" (
    "id" bigserial PRIMARY KEY,
    "operation" text NOT NULL,
    "sourcePath" text NOT NULL,
    "destinationPath" text,
    "newName" text,
    "executedAt" timestamp without time zone NOT NULL,
    "success" boolean NOT NULL,
    "errorMessage" text,
    "reversible" boolean NOT NULL,
    "wasUndone" boolean NOT NULL
);

-- Indexes
CREATE INDEX "idx_file_command_operation" ON "agent_file_command" USING btree ("operation");
CREATE INDEX "idx_file_command_executed" ON "agent_file_command" USING btree ("executedAt");

--
-- ACTION DROP TABLE
--
DROP TABLE "file_index" CASCADE;

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
    "summary" text,
    "tagsJson" text,
    "documentCategory" text,
    "fileCreatedAt" timestamp without time zone,
    "fileModifiedAt" timestamp without time zone,
    "wordCount" bigint,
    "isTextContent" boolean NOT NULL,
    "status" text NOT NULL,
    "errorMessage" text,
    "embeddingModel" text,
    "indexedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "file_index_path_unique" ON "file_index" USING btree ("path");
CREATE INDEX "file_index_content_hash" ON "file_index" USING btree ("contentHash");
CREATE INDEX "file_index_status" ON "file_index" USING btree ("status");
CREATE INDEX "file_index_category" ON "file_index" USING btree ("documentCategory");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ignore_pattern" (
    "id" bigserial PRIMARY KEY,
    "pattern" text NOT NULL,
    "patternType" text NOT NULL,
    "description" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "ignore_pattern_unique" ON "ignore_pattern" USING btree ("pattern");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "indexing_job_detail" (
    "id" bigserial PRIMARY KEY,
    "jobId" bigint NOT NULL,
    "filePath" text NOT NULL,
    "status" text NOT NULL,
    "startedAt" timestamp without time zone,
    "completedAt" timestamp without time zone,
    "errorMessage" text
);

-- Indexes
CREATE INDEX "idx_job_detail_job" ON "indexing_job_detail" USING btree ("jobId");
CREATE INDEX "idx_job_detail_status" ON "indexing_job_detail" USING btree ("status");
CREATE INDEX "idx_job_detail_path" ON "indexing_job_detail" USING btree ("filePath");


--
-- MIGRATION VERSION FOR semantic_butler
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('semantic_butler', '20251221225505777', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251221225505777', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


--
-- MIGRATION VERSION FOR 'serverpod_auth_idp', 'serverpod_auth_core'
--
DELETE FROM "serverpod_migrations"WHERE "module" IN ('serverpod_auth_idp', 'serverpod_auth_core');

COMMIT;
