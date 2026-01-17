-- Migration: Add vector index for performance
-- Created: 2025-01-16
-- 
-- This migration adds IVFFlat index for efficient vector similarity search.
-- Without this index, every search requires a full table scan.

-- Create IVFFlat index for vector similarity search
-- This dramatically improves search performance from O(n) to O(log n)
-- The 'lists' parameter (100) is tuned for medium-sized datasets
-- Increase to 200-500 for larger datasets (>1M vectors)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_embedding_ivfflat
ON document_embedding
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Composite index for filtering by status with covering columns
-- This speeds up queries that filter by status and order by indexedAt
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_file_index_status_indexed
ON file_index (status, "indexedAt" DESC)
WHERE status = 'indexed';

-- Index for path lookups (frequently used for duplicate checking)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_file_index_path
ON file_index (path);

-- Index for fileIndexId foreign key lookups
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_document_embedding_file_index_id
ON document_embedding ("fileIndexId");

-- Update statistics for query planner to make optimal decisions
ANALYZE document_embedding;
ANALYZE file_index;
