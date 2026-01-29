/// Configuration constants for search functionality
/// Centralizes magic numbers and configurable values
class SearchConfig {
  SearchConfig._();

  // ==========================================================================
  // SEARCH LIMITS
  // ==========================================================================

  /// Maximum number of results per search request (prevents DoS)
  static const int maxSearchLimit = 100;

  /// Default number of results per search
  static const int defaultSearchLimit = 10;

  /// Maximum offset for pagination
  static const int maxPaginationOffset = 10000;

  /// Maximum query length allowed
  static const int maxQueryLength = 1000;

  /// Minimum query length for debounced search
  static const int minQueryLength = 2;

  // ==========================================================================
  // RELEVANCE THRESHOLDS
  // ==========================================================================

  /// Default relevance threshold for semantic search
  static const double defaultRelevanceThreshold = 0.3;

  /// Minimum relevance threshold allowed
  static const double minRelevanceThreshold = 0.0;

  /// Maximum relevance threshold allowed
  static const double maxRelevanceThreshold = 1.0;

  // ==========================================================================
  // HYBRID SEARCH WEIGHTS
  // ==========================================================================

  /// Default weight for semantic component in hybrid search
  static const double defaultSemanticWeight = 0.7;

  /// Default weight for keyword component in hybrid search
  static const double defaultKeywordWeight = 0.3;

  // ==========================================================================
  // RATE LIMITING
  // ==========================================================================

  /// Maximum semantic search requests per minute
  static const int semanticSearchRateLimit = 60;

  /// Maximum AI search requests per minute
  static const int aiSearchRateLimit = 30;

  /// Maximum facet requests per minute
  static const int facetRateLimit = 60;

  // ==========================================================================
  // AI SEARCH
  // ==========================================================================

  /// Maximum steps for AI agent search loop
  static const int aiAgentMaxSteps = 5;

  /// Maximum results from terminal search per location
  static const int terminalSearchMaxResults = 100;

  /// Maximum results from terminal search with specific location
  static const int terminalSearchMaxResultsWithLocation = 300;

  /// Timeout for terminal search (seconds)
  static const int terminalSearchTimeoutSeconds = 30;

  /// Timeout for terminal search with specific location (seconds)
  static const int terminalSearchTimeoutSecondsWithLocation = 45;

  // ==========================================================================
  // FACETS
  // ==========================================================================

  /// Maximum number of facet entries per facet type
  static const int maxFacetEntries = 10;

  // ==========================================================================
  // HISTORY
  // ==========================================================================

  /// Maximum search history entries to return
  static const int maxSearchHistoryEntries = 50;

  /// Maximum progress history entries in memory
  static const int maxProgressHistoryEntries = 20;

  // ==========================================================================
  // CACHING
  // ==========================================================================

  /// Cache TTL for search results (minutes)
  static const int searchResultCacheTtlMinutes = 5;

  /// Cache TTL for recent documents (minutes)
  static const int recentDocsCacheTtlMinutes = 1;

  // ==========================================================================
  // UI
  // ==========================================================================

  /// Debounce duration for search input (milliseconds)
  static const int searchDebounceDurationMs = 300;

  /// Pagination debounce duration (milliseconds)
  static const int paginationDebounceDurationMs = 300;

  /// Maximum tags to show before "show more"
  static const int maxVisibleTags = 5;

  /// Preview text max lines
  static const int previewMaxLines = 3;
}
