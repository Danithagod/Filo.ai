-- Semantic Desktop Butler - Supabase Setup Script
-- Run this in your Supabase SQL Editor BEFORE applying Serverpod migrations

-- ===========================================
-- 1. Enable pgvector extension
-- ===========================================
CREATE EXTENSION IF NOT EXISTS vector;

-- ===========================================
-- 2. Add vector column to document_embedding table
-- (Run this AFTER Serverpod migrations are applied)
-- ===========================================
-- Note: Run this after the initial migration creates the tables

-- ALTER TABLE document_embedding 
-- ADD COLUMN IF NOT EXISTS embedding vector(768);

-- CREATE INDEX IF NOT EXISTS idx_embedding_vector 
-- ON document_embedding USING ivfflat (embedding vector_cosine_ops)
-- WITH (lists = 100);

-- ===========================================
-- 3. Helper function for semantic search
-- ===========================================
-- CREATE OR REPLACE FUNCTION semantic_search(
--     query_embedding vector(768),
--     match_threshold float DEFAULT 0.5,
--     match_count int DEFAULT 10
-- )
-- RETURNS TABLE (
--     id bigint,
--     file_index_id bigint,
--     similarity float
-- )
-- LANGUAGE plpgsql
-- AS $$
-- BEGIN
--     RETURN QUERY
--     SELECT 
--         de.id,
--         de."fileIndexId",
--         1 - (de.embedding <=> query_embedding) as similarity
--     FROM document_embedding de
--     WHERE 1 - (de.embedding <=> query_embedding) > match_threshold
--     ORDER BY de.embedding <=> query_embedding
--     LIMIT match_count;
-- END;
-- $$;

-- ===========================================
-- NOTES:
-- ===========================================
-- 1. First run just the CREATE EXTENSION command
-- 2. Then run Serverpod migrations: dart run bin/main.dart --apply-migrations
-- 3. Then uncomment and run the ALTER TABLE and CREATE INDEX commands
-- 4. The semantic search function is optional - we handle search in Dart code
