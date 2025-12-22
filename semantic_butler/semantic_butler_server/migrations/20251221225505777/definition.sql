BEGIN;

--
-- Class AgentFileCommand as table agent_file_command
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
-- Class DocumentEmbedding as table document_embedding
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
-- Class FileIndex as table file_index
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
-- Class IgnorePattern as table ignore_pattern
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
-- Class IndexingJob as table indexing_job
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
-- Class IndexingJobDetail as table indexing_job_detail
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
-- Class SearchHistory as table search_history
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
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


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


COMMIT;
