import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../config/ai_models.dart';
import 'query_correction_service.dart';
import 'openrouter_client.dart';
import 'terminal_service.dart' as terminal;
import 'circuit_breaker.dart';
import '../services/search_tools.dart';
import '../prompts/agent_system_prompt.dart';
import 'smart_rate_limiter.dart';
import 'search_conversation_provider.dart';
import '../utils/cross_platform_paths.dart';
import '../utils/encoding_detector.dart';
import '../utils/cancellation_token.dart';
import '../utils/path_validator.dart';

/// Service for AI-powered file search
///
/// Combines semantic index search with terminal-based file discovery
/// using AI to orchestrate the best search strategy.
class AISearchService {
  final OpenRouterClient _client;
  final terminal.TerminalService _terminal;
  final CircuitBreaker _circuitBreaker;

  // Query intent cache for performance
  static final Map<String, _CachedIntent> _intentCache = {};
  static const Duration _intentCacheTTL = Duration(minutes: 5);

  AISearchService({
    required OpenRouterClient client,
    terminal.TerminalService? terminalService,
  }) : _client = client,
       _terminal = terminalService ?? terminal.TerminalService(),
       _circuitBreaker = CircuitBreakerRegistry.instance.getBreaker(
         'ai_search',
       );

  // ==========================================================================
  // QUERY PARSING
  // ==========================================================================

  /// Analyze query to determine search intent and strategy
  Future<SearchIntent> parseQuery(String query, {String? sessionId}) async {
    // Check cache first
    final cacheKey = '$query:${sessionId ?? "none"}';
    final cached = _intentCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.intent;
    }

    // Check rate limit
    if (!SmartRateLimiter.instance.check(
      'search',
      clientId: sessionId ?? 'system',
    )) {
      throw Exception('Rate limit exceeded (429)');
    }

    // Get conversation context if session available
    String context = '';
    if (sessionId != null) {
      context = SearchConversationProvider.instance.getContextForAI(sessionId);
    }

    // Use AI to understand the query intent
    final messages = <ChatMessage>[
      ChatMessage.system('''
You are a query analyzer for a file search system.
Extract the following entities from the user's query:

$context

1. DATE expressions: "last week", "yesterday", "files from 2023",
   "modified in the past month", "today", "this year"

2. SIZE expressions: "larger than 10MB", "small files under 5MB",
   "files bigger than 1GB", "tiny files"

3. LOCATION expressions: "in Documents", "on D drive",
   "in Downloads folder", "on my desktop"

4. CONTENT expressions: "files containing 'TODO'",
   "documents with 'invoice'", "files mentioning 'meeting'"

5. COUNT expressions: "more than 5 pages", "long documents",
   "files with at least 1000 words"

Respond with JSON:
{
  "intent": "specific_file|file_type|semantic_content|location|mixed|temporal|size_based",
  "strategy": "semantic_first|ai_only|hybrid",
  "search_terms": ["term1", "term2"],
  "file_patterns": ["*.pdf"],
  "is_folder_search": false,
  "date_range": {
    "from": "2024-01-01" | null,
    "to": "2024-01-31" | null,
    "original_text": "last month" | null,
    "type": "RELATIVE" | "ABSOLUTE" | "RANGE"
  },
  "size_range": {
    "min_bytes": 10485760,  // 10MB
    "max_bytes": null,
    "original_text": "larger than 10MB"
  },
  "location_paths": ["C:\\\\Users\\\\Documents", "D:\\\\"],
  "content_terms": ["TODO", "invoice"],
  "count_expression": {
    "min_count": 5,
    "unit": "pages"
  },
  "reasoning": "Explanation of the analysis"
}

Current date: ${DateTime.now().toIso8601String()}
'''),
      ChatMessage.user(query),
    ];

    try {
      final response = await _circuitBreaker.execute(
        () => _client.chatCompletion(
          model: AIModels.chatGeminiFlash,
          messages: messages,
          temperature: 0.2,
        ),
      );

      String jsonStr = response.content.trim();
      // Remove markdown if present
      if (jsonStr.startsWith('```')) {
        final start = jsonStr.indexOf('{');
        final end = jsonStr.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          jsonStr = jsonStr.substring(start, end + 1);
        }
      }

      final parsed = _parseJson(jsonStr);

      // Parse Date Range
      DateExpression? dateRange;
      if (parsed['date_range'] != null) {
        final d = parsed['date_range'];
        dateRange = DateExpression(
          from: d['from'] != null ? DateTime.parse(d['from']) : null,
          to: d['to'] != null ? DateTime.parse(d['to']) : null,
          originalText: d['original_text'],
          type: _parseDateType(d['type']),
        );
      }

      // Parse Size Range
      SizeExpression? sizeRange;
      if (parsed['size_range'] != null) {
        final s = parsed['size_range'];
        sizeRange = SizeExpression(
          minBytes: s['min_bytes'],
          maxBytes: s['max_bytes'],
          originalText: s['original_text'],
        );
      }

      // Parse Count Expression
      CountExpression? countExpr;
      if (parsed['count_expression'] != null) {
        final c = parsed['count_expression'];
        countExpr = CountExpression(
          minCount: c['min_count'],
          maxCount: c['max_count'],
          unit: c['unit'],
        );
      }

      final intent = SearchIntent(
        intent: parsed['intent'] as String? ?? 'mixed',
        strategy: parsed['strategy'] as String? ?? 'hybrid',
        searchTerms: _parseStringList(parsed['search_terms']),
        filePatterns: _parseStringList(parsed['file_patterns']),
        isFolderSearch: parsed['is_folder_search'] as bool? ?? false,
        reasoning: parsed['reasoning'] as String?,
        dateRange: dateRange,
        sizeRange: sizeRange,
        locationPaths: _parseStringList(parsed['location_paths']),
        contentSearchTerms: _parseStringList(parsed['content_terms']),
        countExpression: countExpr,
      );

      // Cache the result
      _intentCache[cacheKey] = _CachedIntent(intent);

      // Schedule cache cleanup
      Future.delayed(_intentCacheTTL, () => _intentCache.remove(cacheKey));

      return intent;
    } catch (e) {
      // Fallback to simple heuristics
      return _parseQueryHeuristically(query);
    }
  }

  /// Enhanced heuristic-based query parsing (fallback when AI unavailable)
  SearchIntent _parseQueryHeuristically(String query) {
    final lowerQuery = query.toLowerCase();

    // Check for folder-related queries
    final isFolderSearch =
        lowerQuery.contains('folder') ||
        lowerQuery.contains('directory') ||
        lowerQuery.contains('where is') ||
        lowerQuery.contains('locate');

    // Check for file type patterns
    final fileTypeMatches = RegExp(r'\*\.(\w+)').allMatches(query);
    final filePatterns = fileTypeMatches.map((m) => m.group(0)!).toList();

    // Extract file extensions from query (e.g., "pdf files", "docx documents")
    final extensionMatches = RegExp(
      r'\b(pdf|doc|docx|xls|xlsx|ppt|pptx|txt|jpg|png|gif|mp4|mp3|zip|rar)\b',
    ).allMatches(lowerQuery);
    for (final match in extensionMatches) {
      final ext = match.group(1)!;
      if (!filePatterns.any((p) => p.contains(ext))) {
        filePatterns.add('*.$ext');
      }
    }

    // Determine intent
    String intent;
    String strategy;

    if (lowerQuery.contains('where') ||
        lowerQuery.contains('find') ||
        lowerQuery.contains('locate')) {
      intent = 'specific_file';
      strategy = 'ai_only';
    } else if (filePatterns.isNotEmpty) {
      intent = 'file_type';
      strategy = 'ai_only';
    } else {
      intent = 'semantic_content';
      strategy = 'semantic_first';
    }

    // Extract search terms (remove common words)
    final stopWords = {
      'where',
      'is',
      'the',
      'find',
      'locate',
      'search',
      'for',
      'my',
      'folder',
      'file',
      'files',
      'document',
      'documents',
      'directory',
      'located',
      'a',
      'an',
      'show',
      'me',
      'look',
      'looking',
    };

    final terms = query
        .split(RegExp(r'\s+'))
        .where((w) => !stopWords.contains(w.toLowerCase()))
        .where((w) => w.length > 2)
        .toList();

    // ============ Extract Date Expressions ============
    DateExpression? dateRange;
    final now = DateTime.now();

    // Today
    if (lowerQuery.contains('today')) {
      dateRange = DateExpression(
        from: DateTime(now.year, now.month, now.day),
        to: DateTime(now.year, now.month, now.day, 23, 59, 59),
        originalText: 'today',
        type: DateType.relative,
      );
    }
    // Yesterday
    else if (lowerQuery.contains('yesterday')) {
      final yesterday = now.subtract(const Duration(days: 1));
      dateRange = DateExpression(
        from: DateTime(yesterday.year, yesterday.month, yesterday.day),
        to: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
          59,
        ),
        originalText: 'yesterday',
        type: DateType.relative,
      );
    }
    // This week
    else if (lowerQuery.contains('this week')) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      dateRange = DateExpression(
        from: DateTime(weekStart.year, weekStart.month, weekStart.day),
        to: DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
          23,
          59,
          59,
        ).add(const Duration(days: 6)),
        originalText: 'this week',
        type: DateType.relative,
      );
    }
    // Last week
    else if (lowerQuery.contains('last week')) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + 7));
      dateRange = DateExpression(
        from: DateTime(weekStart.year, weekStart.month, weekStart.day),
        to: DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
          23,
          59,
          59,
        ).add(const Duration(days: 6)),
        originalText: 'last week',
        type: DateType.relative,
      );
    }
    // This month
    else if (lowerQuery.contains('this month')) {
      dateRange = DateExpression(
        from: DateTime(now.year, now.month, 1),
        to: DateTime(
          now.year,
          now.month + 1,
          1,
        ).subtract(const Duration(seconds: 1)),
        originalText: 'this month',
        type: DateType.relative,
      );
    }
    // Last month
    else if (lowerQuery.contains('last month')) {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      dateRange = DateExpression(
        from: lastMonth,
        to: DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(seconds: 1)),
        originalText: 'last month',
        type: DateType.relative,
      );
    }
    // This year
    else if (lowerQuery.contains('this year')) {
      dateRange = DateExpression(
        from: DateTime(now.year, 1, 1),
        to: DateTime(now.year, 12, 31, 23, 59, 59),
        originalText: 'this year',
        type: DateType.relative,
      );
    }
    // Last year
    else if (lowerQuery.contains('last year')) {
      dateRange = DateExpression(
        from: DateTime(now.year - 1, 1, 1),
        to: DateTime(now.year - 1, 12, 31, 23, 59, 59),
        originalText: 'last year',
        type: DateType.relative,
      );
    }
    // Past N days
    else {
      final pastDaysMatch = RegExp(
        r'past\s+(\d+)\s+days?|last\s+(\d+)\s+days?',
      ).firstMatch(lowerQuery);
      if (pastDaysMatch != null) {
        final days =
            int.tryParse(
              pastDaysMatch.group(1) ?? pastDaysMatch.group(2) ?? '',
            ) ??
            7;
        final cutoff = now.subtract(Duration(days: days));
        dateRange = DateExpression(
          from: cutoff,
          to: null,
          originalText: 'past $days days',
          type: DateType.relative,
        );
      }
    }

    // Absolute year patterns (e.g., "files from 2023")
    final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(query);
    if (yearMatch != null && dateRange == null) {
      final year = int.tryParse(yearMatch.group(0)!) ?? now.year;
      dateRange = DateExpression(
        from: DateTime(year, 1, 1),
        to: DateTime(year, 12, 31, 23, 59, 59),
        originalText: year.toString(),
        type: DateType.absolute,
      );
    }

    // ============ Extract Size Expressions ============
    SizeExpression? sizeRange;

    // Size patterns
    final sizeValueMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(MB|GB|KB)',
      caseSensitive: false,
    ).firstMatch(query);
    if (sizeValueMatch != null) {
      sizeRange = AISearchService._parseSizeWithUnit(sizeValueMatch);
    }

    final comparativeSizePatterns = {
      RegExp(
        r'(larger|bigger|greater|more\s+than)\s+than?\s*(\d+(?:\.\d+)?)\s*(MB|GB|KB)',
        caseSensitive: false,
      ): (match) =>
          _parseComparativeSize(match, true),
      RegExp(
        r'(smaller|less|under|below)\s+than?\s*(\d+(?:\.\d+)?)\s*(MB|GB|KB)',
        caseSensitive: false,
      ): (match) =>
          _parseComparativeSize(match, false),
      RegExp(r'\b(huge|large|big)\s+files?\b', caseSensitive: false): (_) =>
          SizeExpression(
            minBytes: 100 * 1024 * 1024,
            originalText: 'large files',
          ),
      RegExp(r'\b(small|tiny|little)\s+files?\b', caseSensitive: false): (_) =>
          SizeExpression(maxBytes: 1024 * 1024, originalText: 'small files'),
    };

    if (sizeRange == null) {
      // Only try comparative if direct size wasn't found
      for (final entry in comparativeSizePatterns.entries) {
        final match = entry.key.firstMatch(query);
        if (match != null) {
          sizeRange = entry.value(match);
          break;
        }
      }
    }

    // ============ Extract Location Paths ============
    final locationPaths = <String>[];

    // Windows drive letters
    final driveMatches = RegExp(
      r'\b([a-zA-Z])\s*drive?|drive\s*([a-zA-Z])\b',
      caseSensitive: false,
    ).allMatches(query);

    for (final match in driveMatches) {
      final driveLetter = match.group(1) ?? match.group(2);
      if (driveLetter != null) {
        locationPaths.add('${driveLetter.toUpperCase()}:\\');
      }
    }

    // Common folder names
    final folderPatterns = {
      'documents': ['Documents', 'My Documents'],
      'desktop': ['Desktop'],
      'downloads': ['Downloads'],
      'pictures': ['Pictures', 'My Pictures'],
      'videos': ['Videos', 'My Videos'],
      'music': ['Music', 'My Music'],
      'onedrive': ['OneDrive'],
    };

    for (final entry in folderPatterns.entries) {
      if (lowerQuery.contains(entry.key)) {
        final homeDir =
            Platform.environment['USERPROFILE'] ??
            Platform.environment['HOME'] ??
            '';
        if (homeDir.isNotEmpty) {
          for (final folderName in entry.value) {
            final candidate = '$homeDir\\$folderName';
            if (Directory(candidate).existsSync()) {
              locationPaths.add(candidate);
              break;
            }
          }
        }
      }
    }

    // ============ Extract Content Search Terms ============
    final contentSearchTerms = <String>[];

    final contentPatterns = [
      RegExp(r'''contain(?:ing|s)?\s+['"]([^'"]+)['"]''', caseSensitive: false),
      RegExp(r'''with\s+['"]([^'"]+)['"]''', caseSensitive: false),
      RegExp(
        r'''mention(?:ing|s)?\s+['"]([^'"]+)['"]''',
        caseSensitive: false,
      ),
      RegExp(r'''about\s+['"]([^'"]+)['"]''', caseSensitive: false),
    ];

    for (final pattern in contentPatterns) {
      for (final match in pattern.allMatches(query)) {
        final term = match.group(1);
        if (term != null && term.isNotEmpty) {
          contentSearchTerms.add(term);
        }
      }
    }

    // Also add quoted strings
    final quotedMatches = RegExp(r'"([^"]+)"').allMatches(query);
    for (final match in quotedMatches) {
      final term = match.group(1);
      if (term != null &&
          term.isNotEmpty &&
          !contentSearchTerms.contains(term)) {
        contentSearchTerms.add(term);
      }
    }

    return SearchIntent(
      intent: intent,
      strategy: strategy,
      searchTerms: terms,
      filePatterns: filePatterns,
      isFolderSearch: isFolderSearch,
      dateRange: dateRange,
      sizeRange: sizeRange,
      locationPaths: locationPaths,
      contentSearchTerms: contentSearchTerms,
      countExpression: null,
      reasoning: 'Heuristic analysis (AI unavailable)',
    );
  }

  // ==========================================================================
  // SEARCH EXECUTION
  // ==========================================================================

  /// Ensure required PostgreSQL extensions are available
  Future<void> _ensureExtensions(Session session) async {
    try {
      // These require superuser or appropriate permissions
      // In a local desktop app context, the user usually has these
      await session.db.unsafeQuery('CREATE EXTENSION IF NOT EXISTS vector');
      await session.db.unsafeQuery('CREATE EXTENSION IF NOT EXISTS pg_trgm');
    } catch (e) {
      session.log(
        'CRITICAL: Database extensions (vector, pg_trgm) missing! Vector search will fail. Error: $e',
        level: LogLevel.warning,
      );
      throw Exception(
        'Database extensions not available. Please install pgvector and pg_trgm extensions.',
      );
    }
  }

  /// Execute AI-powered search with streaming progress
  Stream<AISearchProgress> executeSearch(
    Session session,
    String query, {
    SearchStrategy strategy = SearchStrategy.hybrid,
    int maxResults = 20,
    SearchFilters? filters,
    CancellationToken? cancellationToken,
  }) async* {
    await _ensureExtensions(session);

    // Create or use provided cancellation token
    final token = cancellationToken ?? CancellationToken();

    try {
      // Check if already cancelled
      token.throwIfCancelled();

      if (filters?.sessionId != null) {
        // Log conversation turn
        // We log it at the end usually, but here we can prepare
      }

      // Step 1: Parse query intent
      yield AISearchProgress(
        type: 'thinking',
        message: 'Analyzing your search query...',
        progress: 0.05,
      );

      token.throwIfCancelled();

      final intent = await parseQuery(query, sessionId: filters?.sessionId);

      yield AISearchProgress(
        type: 'thinking',
        message: 'Strategy: ${intent.reasoning ?? intent.strategy}',
        progress: 0.1,
      );

      // Determine effective strategy
      final effectiveStrategy = _determineStrategy(strategy, intent);

      // Apply extracted filters
      final intentFilters = _buildFiltersFromIntent(intent);

      // If user provided filters, they take precedence (or merge? for now simple fallback)
      // Actually merging is better, but let's default to provided if not null
      final effectiveFilters = filters ?? intentFilters;

      // Step 2: Execute search based on strategy
      final allResults = <AISearchResult>[];
      final seenPaths = <String>{}; // For real-time deduplication
      final progressController = StreamController<AISearchProgress>();

      // Register controller for automatic cleanup on cancellation
      token.registerController(progressController);

      // Start Parallel Search Tasks
      final searchTasks = <Future<void>>[];

      void safeAdd(AISearchProgress p) {
        if (token.isCancelled) return;
        if (!progressController.isClosed) {
          progressController.add(p);
        }
      }

      if (effectiveStrategy == SearchStrategy.semanticFirst ||
          effectiveStrategy == SearchStrategy.hybrid) {
        searchTasks.add(() async {
          try {
            token.throwIfCancelled();

            safeAdd(
              AISearchProgress(
                type: 'searching',
                message: 'Searching indexed documents...',
                source: 'semantic',
                progress: 0.2,
              ),
            );

            final semanticResults = await _searchIndex(
              session,
              query,
              maxResults,
              threshold: 0.3,
              filters: effectiveFilters,
              searchTerms: intent.searchTerms,
            );

            token.throwIfCancelled();

            // Add results with deduplication
            for (final result in semanticResults) {
              final normalizedPath = result.path.toLowerCase();
              if (seenPaths.add(normalizedPath)) {
                allResults.add(result);
              }
            }

            // Early termination check
            if (allResults.length >= maxResults * 2) {
              token.cancel();
              return;
            }

            if (semanticResults.isNotEmpty) {
              safeAdd(
                AISearchProgress(
                  type: 'found',
                  message: 'Found ${semanticResults.length} results in index',
                  source: 'semantic',
                  results: List.of(allResults),
                  progress: 0.4,
                ),
              );
            }
          } catch (e) {
            session.log('Semantic search failed: $e', level: LogLevel.warning);
          }
        }());
      }

      if (effectiveStrategy == SearchStrategy.aiOnly ||
          effectiveStrategy == SearchStrategy.hybrid) {
        searchTasks.add(() async {
          try {
            token.throwIfCancelled();

            await for (final p in _executeTerminalSearch(
              session,
              intent,
              allResults,
              maxResults,
              seenPaths,
              startProgress: allResults.isEmpty ? 0.2 : 0.5,
            )) {
              token.throwIfCancelled();
              safeAdd(p);
            }
          } catch (e) {
            if (e is CancelledException) {
              session.log('Terminal search cancelled', level: LogLevel.debug);
            } else {
              session.log(
                'Terminal search failed: $e',
                level: LogLevel.warning,
              );
            }
          }
        }());
      }

      // Run tasks and close controller with timeout protection
      unawaited(
        Future.wait(searchTasks)
            .timeout(
              const Duration(minutes: 10),
              onTimeout: () {
                session.log(
                  'Search tasks timed out after 10 minutes',
                  level: LogLevel.warning,
                );
                token.cancel();
                return <void>[];
              },
            )
            .then((_) {
              if (!progressController.isClosed) {
                progressController.close();
              }
            })
            .catchError((e) {
              session.log('Search tasks error: $e', level: LogLevel.warning);
              if (!progressController.isClosed) {
                progressController.close();
              }
            }),
      );

      // Yield merged progress
      await for (final progress in progressController.stream) {
        token.throwIfCancelled();
        yield progress;
      }

      token.throwIfCancelled();

      // Proactive Step: If still few results, use AI to suggest targeted search locations/patterns
      if (allResults.length < 5) {
        yield* _runAgentLoop(
          session,
          query,
          intent,
          maxResults,
          allResults,
          token,
        );
      }

      token.throwIfCancelled();

      // Step 3: Aggregate and rank results
      yield AISearchProgress(
        type: 'thinking',
        message: 'Ranking results...',
        progress: 0.95,
      );

      final rankedResults = _rankResults(allResults, query);

      // Step 4: Check for query suggestions ("Did you mean?")
      String? suggestedQuery;
      try {
        suggestedQuery = await QueryCorrectionService(
          client: _client,
        ).getCorrectedQuery(session, query);
      } catch (e) {
        session.log(
          'Query correction failed in AISearchService: $e',
          level: LogLevel.debug,
        );
      }

      if (suggestedQuery != null) {
        for (var result in rankedResults) {
          result.suggestedQuery = suggestedQuery;
        }
      }

      // Step 5: Return final results
      yield AISearchProgress(
        type: 'complete',
        message: 'Search complete',
        results: rankedResults.take(maxResults).toList(),
        progress: 1.0,
      );

      // Log conversation turn if success
      if (filters?.sessionId != null) {
        SearchConversationProvider.instance.addTurn(
          filters!.sessionId!,
          query,
          'Found ${rankedResults.length} results',
        );
      }
    } catch (e) {
      if (e is CancelledException) {
        session.log('AI search cancelled: $query', level: LogLevel.debug);
        yield AISearchProgress(
          type: 'cancelled',
          message: 'Search cancelled',
          progress: 1.0,
        );
      } else {
        rethrow;
      }
    } finally {
      // Cleanup
    }
  }

  /// Execute terminal-based search across drives or specific locations
  Stream<AISearchProgress> _executeTerminalSearch(
    Session session,
    SearchIntent intent,
    List<AISearchResult> existingResults,
    int maxResults,
    Set<String> seenPaths, {
    double startProgress = 0.2,
  }) async* {
    // Determine search paths based on intent.locationPaths
    final List<SearchPath> searchPaths = [];

    if (intent.locationPaths.isNotEmpty) {
      // User specified locations - use those
      yield AISearchProgress(
        type: 'searching',
        message:
            'Searching in ${intent.locationPaths.length} specified location(s)...',
        source: 'terminal',
        progress: startProgress,
      );

      for (final locPath in intent.locationPaths) {
        final normalizedPath = _normalizePath(locPath);

        // Security: Check for path traversal
        if (PathValidator.hasPathTraversal(normalizedPath)) {
          session.log(
            'Path traversal attempt detected: $normalizedPath',
            level: LogLevel.warning,
          );
          continue;
        }

        // Security: Validate path is safe to search
        if (!PathValidator.isPathSafe(normalizedPath)) {
          session.log(
            'Location path rejected (security): $normalizedPath',
            level: LogLevel.warning,
          );
          continue;
        }

        final validatedPath = PathValidator.validateSearchPath(normalizedPath);
        if (validatedPath == null) {
          session.log(
            'Location path does not exist or is invalid: $normalizedPath',
            level: LogLevel.warning,
          );
          continue;
        }
        // Verify path exists
        final dir = Directory(validatedPath);
        if (await dir.exists()) {
          searchPaths.add(
            SearchPath(
              path: validatedPath,
              description: _getLocationDescription(validatedPath),
              isDrive: false,
            ),
          );
        } else {
          session.log(
            'Location path does not exist: $validatedPath',
            level: LogLevel.warning,
          );
        }
      }

      // If no valid paths found, fall back to drives
      if (searchPaths.isEmpty) {
        yield AISearchProgress(
          type: 'warning',
          message: 'Specified locations not found. Searching all drives...',
          source: 'terminal',
          progress: startProgress,
        );
        searchPaths.addAll(await _getAvailableDrives());
      }
    } else {
      // No specific locations - search all drives
      yield AISearchProgress(
        type: 'searching',
        message: 'Discovering available drives...',
        source: 'terminal',
        progress: startProgress,
      );

      searchPaths.addAll(await _getAvailableDrives());
    }

    if (searchPaths.isEmpty) {
      yield AISearchProgress(
        type: 'error',
        message: 'No searchable locations found',
        error: 'No drives or locations accessible',
      );
      return;
    }

    // Calculate progress per location
    final progressPerLocation = (0.9 - startProgress) / searchPaths.length;
    var currentProgress = startProgress;

    // Search each location
    for (final searchPath in searchPaths) {
      yield AISearchProgress(
        type: 'searching',
        message: 'Searching ${searchPath.description}...',
        source: 'terminal',
        drive: searchPath.path,
        progress: currentProgress,
      );

      try {
        // Try search terms and file patterns
        final patternsToTry = <String>{
          ...intent.searchTerms,
          ...intent.filePatterns,
        };

        for (final pattern in patternsToTry) {
          final terminalMaxResults = intent.locationPaths.isNotEmpty
              ? 300
              : 100;
          final terminalTimeoutSeconds = intent.locationPaths.isNotEmpty
              ? 45
              : 30;
          final results = await _terminal.crossPlatformSearch(
            pattern,
            directory: searchPath.path,
            foldersOnly: intent.isFolderSearch,
            maxResults: terminalMaxResults,
            timeoutSeconds: terminalTimeoutSeconds,
          );

          if (results.success) {
            final files = results.stdout
                .split('\n')
                .where((l) => l.trim().isNotEmpty)
                .toList();

            for (final filePath in files) {
              final normalizedPath = filePath.toLowerCase();
              if (seenPaths.add(normalizedPath)) {
                final fileName = filePath.split(RegExp(r'[/\\]')).last;
                existingResults.add(
                  AISearchResult(
                    path: filePath,
                    fileName: fileName,
                    isDirectory: intent.isFolderSearch,
                    source: 'terminal',
                    foundVia: 'cross_platform_search',
                    matchReason:
                        'Matched pattern "$pattern" in ${searchPath.description}',
                  ),
                );
              }
            }

            if (files.isNotEmpty) {
              yield AISearchProgress(
                type: 'found',
                message:
                    'Found ${files.length} matches for "$pattern" in ${searchPath.description}',
                source: 'terminal',
                drive: searchPath.path,
                results: existingResults,
                progress: currentProgress + progressPerLocation * 0.5,
              );
            }
          }
        }
      } catch (e) {
        session.log(
          'Search failed for ${searchPath.path}: $e',
          level: LogLevel.warning,
        );
      }

      currentProgress += progressPerLocation;

      // Early exit if we have enough results
      if (existingResults.length >= maxResults * 2) {
        yield AISearchProgress(
          type: 'thinking',
          message: 'Found sufficient results, stopping search...',
          progress: currentProgress,
        );
        break;
      }
    }

    yield AISearchProgress(
      type: 'searching',
      message: 'Terminal search complete',
      source: 'terminal',
      progress: 0.9,
    );
  }

  // ==========================================================================
  // AGENT SEARCH
  // ==========================================================================

  /// Execute an agentic search loop with tool calling
  Stream<AISearchProgress> _runAgentLoop(
    Session session,
    String query,
    SearchIntent intent,
    int maxResults,
    List<AISearchResult> allResults,
    CancellationToken token,
  ) async* {
    yield AISearchProgress(
      type: 'thinking',
      message: 'Starting agentic search...',
      progress: 0.1,
    );

    final messages = <ChatMessage>[
      ChatMessage.system(AgentSystemPrompt.systemPrompt),
      ChatMessage.user(query),
    ];

    final foundResults = <AISearchResult>[];
    int steps = 0;
    const maxSteps = 5;

    await _ensureExtensions(session);

    while (steps < maxSteps) {
      steps++;

      try {
        final response = await _circuitBreaker.execute(
          () => _client.chatCompletion(
            model: AIModels.chatGeminiFlash,
            messages: messages,
            tools: SearchTools.allTools,
            temperature: 0.1,
          ),
        );

        final choice = response.choices.first;
        final msg = choice.message;
        messages.add(msg);

        if (msg.toolCalls != null && msg.toolCalls!.isNotEmpty) {
          for (final toolCall in msg.toolCalls!) {
            final funcName = toolCall.function?.name;
            yield AISearchProgress(
              type: 'thinking',
              message: 'Agent executing $funcName...',
              progress: 0.1 + (steps * 0.15),
            );

            Map<String, dynamic>? toolResult;
            await for (final toolProgress in _executeTool(
              session,
              toolCall,
              foundResults,
              maxResults,
            )) {
              if (toolProgress.type == 'tool_output' &&
                  toolProgress.toolResultJson != null) {
                toolResult =
                    jsonDecode(toolProgress.toolResultJson!)
                        as Map<String, dynamic>;
              }
              yield toolProgress;
            }

            if (toolResult != null) {
              messages.add(
                ChatMessage.tool(jsonEncode(toolResult), toolCall.id!),
              );
            }

            // Yield found results immediately if any new ones
            if (foundResults.isNotEmpty) {
              // Add only new unique results to allResults for cumulative streaming
              for (final res in foundResults) {
                final normalizedPath = res.path.toLowerCase();
                if (!allResults.any(
                  (existing) => existing.path.toLowerCase() == normalizedPath,
                )) {
                  allResults.add(res);
                }
              }

              yield AISearchProgress(
                type: 'found',
                message: 'Agent found ${foundResults.length} potential matches',
                results: List.of(allResults), // Yield cumulative results
                progress: 0.1 + (steps * 0.15),
              );
            }
          }
        } else {
          // No tool calls, likely done or provided answer
          break;
        }
      } catch (e) {
        session.log('Agent step failed: $e', level: LogLevel.error);
        break;
      }
    }
  }

  Stream<AISearchProgress> _executeTool(
    Session session,
    ToolCall toolCall,
    List<AISearchResult> collector,
    int maxResults,
  ) async* {
    final name = toolCall.function?.name;
    final args = toolCall.function?.parsedArguments ?? {};

    try {
      // Dispatch to appropriate handler based on tool name
      switch (name) {
        case SearchTools.searchIndex:
          yield* _executeSearchIndex(session, args, collector);
        case SearchTools.searchTerminal:
          yield* _executeSearchTerminal(args, collector);
        case SearchTools.getDrives:
          yield* _executeGetDrives();
        case SearchTools.deepSearch:
          yield* _executeDeepSearch(args, collector);
        case SearchTools.runCommand:
          yield* _executeRunCommand(args);
        case SearchTools.getFileInfo:
          yield* _executeGetFileInfo(args);
        case SearchTools.readFile:
          yield* _executeReadFile(args);
        case SearchTools.listDirectory:
          yield* _executeListDirectory(args);
        case SearchTools.getSpecialPaths:
          yield* _executeGetSpecialPaths(args);
        case SearchTools.listHiddenFiles:
          yield* _executeListHiddenFiles(args);
        case SearchTools.resolveSymlink:
          yield* _executeResolveSymlink(args);
        default:
          yield _errorProgress('Unknown tool $name', 'Unknown tool $name');
      }
    } catch (e) {
      yield _errorProgress('Error executing tool $name: $e', e.toString());
    }
  }

  // ===========================================================================
  // TOOL HANDLERS - Each tool has its own method for maintainability
  // ===========================================================================

  /// Handle search_index tool - searches the semantic index
  Stream<AISearchProgress> _executeSearchIndex(
    Session session,
    Map<String, dynamic> args,
    List<AISearchResult> collector,
  ) async* {
    final query = args['query'] as String;
    final limit = args['limit'] as int? ?? 10;

    SearchFilters? toolFilters;
    if (args['filters'] != null) {
      final f = args['filters'] as Map<String, dynamic>;
      toolFilters = SearchFilters(
        minSize: (f['min_size'] as num?)?.toInt(),
        maxSize: (f['max_size'] as num?)?.toInt(),
        fileTypes: (f['file_types'] as List?)?.cast<String>(),
        dateFrom: f['date_from'] != null
            ? DateTime.tryParse(f['date_from'] as String)
            : null,
        dateTo: f['date_to'] != null
            ? DateTime.tryParse(f['date_to'] as String)
            : null,
        tags: (f['tags'] as List?)?.cast<String>(),
        contentTerms: (f['content_terms'] as List?)?.cast<String>(),
        locationPaths: (f['location_paths'] as List?)?.cast<String>(),
        minCount: (f['min_count'] as num?)?.toInt(),
        maxCount: (f['max_count'] as num?)?.toInt(),
        countUnit: f['count_unit'] as String?,
      );
    }

    final results = await _searchIndex(
      session,
      query,
      limit,
      filters: toolFilters,
    );

    int added = 0;
    for (final r in results) {
      if (!collector.any((existing) => existing.path == r.path)) {
        r.foundVia = 'agent_index_search';
        collector.add(r);
        added++;
      }
    }

    yield AISearchProgress(
      type: 'tool_output',
      message:
          'search_index: Found ${results.length} results, added $added new.',
      progress: 0.0,
      toolResultJson: jsonEncode({
        'status': 'success',
        'found_count': results.length,
        'new_added': added,
        'details': results
            .map((r) => '${r.fileName} (${r.relevanceScore})')
            .toList(),
      }),
    );
  }

  /// Handle search_terminal tool - cross-platform file search
  Stream<AISearchProgress> _executeSearchTerminal(
    Map<String, dynamic> args,
    List<AISearchResult> collector,
  ) async* {
    final pattern = args['pattern'] as String;
    final path = args['path'] as String?;
    final foldersOnly = args['folders_only'] as bool? ?? false;

    List<String> searchPaths = [];
    if (path != null) {
      searchPaths.add(path);
    } else {
      final drives = await _terminal.listDrives();
      searchPaths.addAll(drives.map((d) => d.path));
    }

    int totalFound = 0;
    final details = <String>[];

    for (final sp in searchPaths) {
      final timeoutSeconds = path != null ? 45 : 30;
      final cmdResult = await _terminal.crossPlatformSearch(
        pattern,
        directory: sp,
        foldersOnly: foldersOnly,
        maxResults: 100,
        timeoutSeconds: timeoutSeconds,
      );

      if (cmdResult.success) {
        final lines = cmdResult.stdout
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        totalFound += lines.length;
        for (final fPath in lines) {
          if (!collector.any((c) => c.path == fPath)) {
            final fileName = fPath.split(RegExp(r'[/\\]')).last;
            collector.add(
              AISearchResult(
                path: fPath,
                fileName: fileName,
                isDirectory: foldersOnly,
                source: 'terminal',
                foundVia: 'agent_cross_platform_search',
                matchReason: 'Matched pattern "$pattern"',
              ),
            );
          }
          if (details.length < 10) details.add(fPath);
        }
      }
    }

    yield AISearchProgress(
      type: 'tool_output',
      message: 'search_terminal: Found $totalFound results.',
      progress: 0.0,
      toolResultJson: jsonEncode({
        'status': 'success',
        'found_count': totalFound,
        'searched_paths': searchPaths,
        'sample_results': details,
      }),
    );
  }

  /// Handle get_drives tool - list available drives
  Stream<AISearchProgress> _executeGetDrives() async* {
    final drives = await _terminal.listDrives();
    yield AISearchProgress(
      type: 'tool_output',
      message: 'get_drives: Found ${drives.length} drives.',
      progress: 0.0,
      toolResultJson: jsonEncode({
        'status': 'success',
        'count': drives.length,
        'drives': drives
            .map(
              (d) => {
                'path': d.path,
                'description': d.description,
                'freeSpace': d.freeSpace,
                'totalSpace': d.totalSpace,
              },
            )
            .toList(),
      }),
    );
  }

  /// Handle deep_search tool - recursive file search
  Stream<AISearchProgress> _executeDeepSearch(
    Map<String, dynamic> args,
    List<AISearchResult> collector,
  ) async* {
    final pattern = args['pattern'] as String;
    final directory = args['directory'] as String?;
    final foldersOnly = args['folders_only'] as bool? ?? false;

    final results = await _terminal.deepSearch(
      pattern,
      directory: directory,
      foldersOnly: foldersOnly,
    );

    final files = results.stdout
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    int added = 0;
    for (final filePath in files) {
      if (!collector.any((r) => r.path == filePath)) {
        final fileName = filePath.split(RegExp(r'[/\\]')).last;
        collector.add(
          AISearchResult(
            path: filePath,
            fileName: fileName,
            isDirectory: foldersOnly,
            source: 'terminal',
            foundVia: 'agent_deep_search',
            matchReason: 'Matched pattern "$pattern"',
          ),
        );
        added++;
      }
    }

    yield AISearchProgress(
      type: 'tool_output',
      message: 'deep_search: Found ${files.length} results, added $added new.',
      progress: 0.0,
      toolResultJson: jsonEncode({
        'status': results.success ? 'success' : 'error',
        'found_count': files.length,
        'new_added': added,
        'sample_results': files.take(10).toList(),
        'stderr': results.stderr,
      }),
    );
  }

  /// Handle run_command tool - execute terminal command
  Stream<AISearchProgress> _executeRunCommand(
    Map<String, dynamic> args,
  ) async* {
    final command = args['command'] as String;
    final workingDirectory = args['working_directory'] as String?;

    final result = await _terminal.execute(
      command,
      workingDirectory: workingDirectory,
      timeout: const Duration(seconds: 120),
      allowPowerShellSearch: true,
    );

    yield AISearchProgress(
      type: 'tool_output',
      message: 'run_command: Completed with exit ${result.exitCode}.',
      progress: 0.0,
      toolResultJson: jsonEncode({
        'status': result.success ? 'success' : 'error',
        'stdout': result.stdout,
        'stderr': result.stderr,
        'exit_code': result.exitCode,
        'truncated': result.truncated,
        'timed_out': result.timedOut,
        'working_directory': result.workingDirectory,
      }),
    );
  }

  /// Handle get_file_info tool - get file metadata
  Stream<AISearchProgress> _executeGetFileInfo(
    Map<String, dynamic> args,
  ) async* {
    final path = args['path'] as String;
    try {
      final file = File(path);
      if (!file.existsSync()) {
        yield _errorProgress('getFileInfo: File not found.', 'File not found');
        return;
      }
      final stat = await file.stat();
      yield AISearchProgress(
        type: 'tool_output',
        message: 'getFileInfo: Retrieved info for $path.',
        progress: 0.0,
        toolResultJson: jsonEncode({
          'status': 'success',
          'size': stat.size,
          'modified': stat.modified.toIso8601String(),
          'accessed': stat.accessed.toIso8601String(),
          'mode': stat.modeString(),
          'type': stat.type.toString(),
        }),
      );
    } catch (e) {
      yield _errorProgress(
        'getFileInfo: Failed to get info for $path: $e',
        'Failed to get info: $e',
      );
    }
  }

  /// Handle read_file tool - read file contents
  Stream<AISearchProgress> _executeReadFile(Map<String, dynamic> args) async* {
    final path = args['path'] as String;
    final lines = args['lines'] as int? ?? 100;
    try {
      final file = File(path);
      if (!file.existsSync()) {
        yield _errorProgress('readFile: File not found.', 'File not found');
        return;
      }

      if (EncodingDetector.isBinary(path)) {
        yield _errorProgress(
          'readFile: File appears to be binary.',
          'File appears to be binary and cannot be read as text',
        );
        return;
      }

      try {
        final content = await EncodingDetector.readFileLinesAsync(
          path,
          maxLines: lines,
        );
        yield AISearchProgress(
          type: 'tool_output',
          message:
              'readFile: Read ${content.split('\n').length} lines from $path.',
          progress: 0.0,
          toolResultJson: jsonEncode({
            'status': 'success',
            'lines_read': content.split('\n').length,
            'content': content,
          }),
        );
      } catch (e) {
        yield _errorProgress(
          'readFile: Failed to read text from $path. File might be binary. ($e)',
          'Failed to read text. File might be binary. ($e)',
        );
      }
    } catch (e) {
      yield _errorProgress(
        'readFile: Failed to read file $path: $e',
        'Failed to read file: $e',
      );
    }
  }

  /// Handle list_directory tool - list directory contents
  Stream<AISearchProgress> _executeListDirectory(
    Map<String, dynamic> args,
  ) async* {
    final path = args['path'] as String;
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) {
        yield _errorProgress(
          'list_directory: Directory not found.',
          'Directory not found',
        );
        return;
      }

      final entries = await dir.list().take(100).toList();
      final details = entries.map((e) {
        final isDir = e is Directory;
        final name = e.path.split(RegExp(r'[/\\]')).last;
        return {'name': name, 'type': isDir ? 'directory' : 'file'};
      }).toList();

      yield AISearchProgress(
        type: 'tool_output',
        message: 'list_directory: Listed ${entries.length} items in $path.',
        progress: 0.0,
        toolResultJson: jsonEncode({
          'status': 'success',
          'item_count': entries.length,
          'items': details,
        }),
      );
    } catch (e) {
      yield _errorProgress(
        'list_directory: Failed to list $path: $e',
        'Failed to list directory: $e',
      );
    }
  }

  /// Handle get_special_paths tool - get system special folders
  Stream<AISearchProgress> _executeGetSpecialPaths(
    Map<String, dynamic> args,
  ) async* {
    final folderType = args['folderType'] as String;
    final path = CrossPlatformPaths.getSpecialFolder(folderType);

    if (path != null) {
      yield AISearchProgress(
        type: 'tool_output',
        message: 'get_special_paths: Found $folderType at $path',
        progress: 0.0,
        toolResultJson: jsonEncode({
          'status': 'success',
          'folder_type': folderType,
          'path': path,
          'platform': CrossPlatformPaths.platformName,
        }),
      );
    } else {
      yield AISearchProgress(
        type: 'tool_output',
        message: 'get_special_paths: Special folder not found: $folderType',
        progress: 0.0,
        toolResultJson: jsonEncode({
          'status': 'error',
          'message': 'Special folder not found: $folderType',
          'available_folders': CrossPlatformPaths.specialFolders.keys.toList(),
        }),
      );
    }
  }

  /// Handle list_hidden_files tool - list hidden files in directory
  Stream<AISearchProgress> _executeListHiddenFiles(
    Map<String, dynamic> args,
  ) async* {
    final path = args['path'] as String? ?? '.';
    final includeSystem = args['includeSystem'] as bool? ?? false;
    final expandedPath = CrossPlatformPaths.expand(path);

    try {
      final dir = Directory(expandedPath);
      if (!dir.existsSync()) {
        yield _errorProgress(
          'list_hidden_files: Directory not found',
          'Directory not found: $expandedPath',
        );
        return;
      }

      final hiddenFiles = await _terminal.listHiddenFiles(
        expandedPath,
        includeSystem: includeSystem,
      );

      yield AISearchProgress(
        type: 'tool_output',
        message: 'list_hidden_files: Found ${hiddenFiles.length} hidden files',
        progress: 0.0,
        toolResultJson: jsonEncode({
          'status': 'success',
          'path': expandedPath,
          'hidden_count': hiddenFiles.length,
          'hidden_files': hiddenFiles.take(100).toList(),
        }),
      );
    } catch (e) {
      yield _errorProgress(
        'list_hidden_files: Failed to list hidden files: $e',
        e.toString(),
      );
    }
  }

  /// Handle resolve_symlink tool - resolve symbolic link target
  Stream<AISearchProgress> _executeResolveSymlink(
    Map<String, dynamic> args,
  ) async* {
    final path = args['path'] as String;
    final expandedPath = CrossPlatformPaths.expand(path);

    try {
      final target = await _terminal.resolveSymlink(expandedPath);

      if (target != null) {
        final file = File(target);
        final dir = Directory(target);
        final targetExists = await file.exists() || await dir.exists();

        yield AISearchProgress(
          type: 'tool_output',
          message: 'resolve_symlink: Resolved symlink to $target',
          progress: 0.0,
          toolResultJson: jsonEncode({
            'status': 'success',
            'link_path': expandedPath,
            'target': target,
            'target_exists': targetExists,
          }),
        );
      } else {
        final file = File(expandedPath);
        final dir = Directory(expandedPath);
        if (await file.exists() || await dir.exists()) {
          yield AISearchProgress(
            type: 'tool_output',
            message: 'resolve_symlink: Path is not a symbolic link',
            progress: 0.0,
            toolResultJson: jsonEncode({
              'status': 'success',
              'link_path': expandedPath,
              'message': 'Path is not a symbolic link',
              'is_symlink': false,
            }),
          );
        } else {
          yield _errorProgress(
            'resolve_symlink: Path not found',
            'Path not found: $expandedPath',
          );
        }
      }
    } catch (e) {
      yield _errorProgress(
        'resolve_symlink: Failed to resolve symlink: $e',
        e.toString(),
      );
    }
  }

  /// Helper to create error progress messages
  AISearchProgress _errorProgress(String message, String errorMessage) {
    return AISearchProgress(
      type: 'tool_output',
      message: message,
      progress: 0.0,
      toolResultJson: jsonEncode({
        'status': 'error',
        'message': errorMessage,
      }),
    );
  }

  /// Search the semantic index using vector similarity
  Future<List<AISearchResult>> _searchIndex(
    Session session,
    String query,
    int limit, {
    double threshold = 0.3,
    SearchFilters? filters,
    List<String>? searchTerms,
  }) async {
    final results = <AISearchResult>[];

    try {
      // 1. Generate embedding for the query
      final embeddingResponse = await _circuitBreaker.execute(
        () => _client.createEmbeddings(
          model: AIModels.embeddingGemini,
          input: [query],
        ),
      );
      final queryEmbedding = embeddingResponse.firstEmbedding;

      final queryEmbeddingJson = jsonEncode(queryEmbedding);

      // 2. Perform discovery using vector similarity, trigram similarity, or keyword matching
      final discoveryConditions = <String>[
        '(de.embedding IS NOT NULL AND (1 - (de.embedding <=> \$1::vector) > \$2))',
        'fi."fileName" % \$3',
      ];

      final parameters = <dynamic>[queryEmbeddingJson, threshold, query];
      int paramIndex = 4;

      if (searchTerms != null && searchTerms.isNotEmpty) {
        final keywordConditions = <String>[];
        for (final term in searchTerms) {
          if (term.length < 3) continue;
          keywordConditions.add('fi."fileName" ILIKE \$$paramIndex');
          parameters.add('%$term%');
          paramIndex++;
        }
        if (keywordConditions.isNotEmpty) {
          discoveryConditions.add('(${keywordConditions.join(" OR ")})');
        }
      }

      final whereConditions = <String>[
        '(${discoveryConditions.join(" OR ")})',
      ];

      if (filters != null) {
        // Date Range
        if (filters.dateFrom != null) {
          whereConditions.add('fi."indexedAt" >= \$$paramIndex');
          parameters.add(filters.dateFrom);
          paramIndex++;
        }
        if (filters.dateTo != null) {
          whereConditions.add('fi."indexedAt" <= \$$paramIndex');
          parameters.add(filters.dateTo);
          paramIndex++;
        }

        // File Size
        if (filters.minSize != null) {
          whereConditions.add('fi."fileSizeBytes" >= \$$paramIndex');
          parameters.add(filters.minSize);
          paramIndex++;
        }
        if (filters.maxSize != null) {
          whereConditions.add('fi."fileSizeBytes" <= \$$paramIndex');
          parameters.add(filters.maxSize);
          paramIndex++;
        }

        // File Types
        if (filters.fileTypes != null && filters.fileTypes!.isNotEmpty) {
          final typeConditions = <String>[];
          for (final type in filters.fileTypes!) {
            if (type == 'pdf') {
              typeConditions.add('fi."mimeType" ILIKE \$$paramIndex');
              parameters.add('%pdf%');
              paramIndex++;
            } else if (type == 'image') {
              typeConditions.add('fi."mimeType" ILIKE \$$paramIndex');
              parameters.add('image/%');
              paramIndex++;
            } else if (type == 'doc') {
              typeConditions.add(
                '(fi."mimeType" ILIKE \$$paramIndex OR fi."fileName" ILIKE \$$paramIndex)',
              );
              parameters.add('%word%');
              paramIndex++;
            } else {
              typeConditions.add('fi."fileName" ILIKE \$$paramIndex');
              parameters.add('%.$type%');
              paramIndex++;
            }
          }
          if (typeConditions.isNotEmpty) {
            whereConditions.add('(${typeConditions.join(" OR ")})');
          }
        }

        // Tags
        if (filters.tags != null && filters.tags!.isNotEmpty) {
          for (final tag in filters.tags!) {
            whereConditions.add('fi."tagsJson" ILIKE \$$paramIndex');
            parameters.add('%"$tag"%');
            paramIndex++;
          }
        }

        // Content Terms
        if (filters.contentTerms != null && filters.contentTerms!.isNotEmpty) {
          for (final term in filters.contentTerms!) {
            whereConditions.add('fi."contentPreview" ILIKE \$$paramIndex');
            parameters.add('%$term%');
            paramIndex++;
          }
        }

        // Location Paths
        if (filters.locationPaths != null &&
            filters.locationPaths!.isNotEmpty) {
          final locConditions = <String>[];
          for (final loc in filters.locationPaths!) {
            // Using ILIKE with escaped backslashes for Windows path prefix match
            locConditions.add('fi."path" ILIKE \$$paramIndex');
            // Double backslashes because ILIKE treats \ as escape char by default
            parameters.add('${loc.replaceAll('\\', '\\\\')}%');
            paramIndex++;
          }
          if (locConditions.isNotEmpty) {
            whereConditions.add('(${locConditions.join(" OR ")})');
          }
        }

        // Word/Page Counts
        if (filters.minCount != null || filters.maxCount != null) {
          // Default to word count if not specified
          final column = filters.countUnit == 'pages'
              ? '"pageCount"'
              : '"wordCount"';
          if (filters.minCount != null) {
            whereConditions.add('fi.$column >= \$$paramIndex');
            parameters.add(filters.minCount);
            paramIndex++;
          }
          if (filters.maxCount != null) {
            whereConditions.add('fi.$column <= \$$paramIndex');
            parameters.add(filters.maxCount);
            paramIndex++;
          }
        }
      }

      final limitParamIndex = paramIndex;
      parameters.add(limit);

      final searchQuery =
          '''
        SELECT
          fi.id as "fileIndexId",
          -- Hybrid score: 70% vector, 30% fuzzy matching (fileName)
          (COALESCE((1 - (de.embedding <=> \$1::vector)), 0) * 0.7 + (similarity(fi."fileName", \$3) * 0.3)) as hybrid_score,
          fi.id, fi.path, fi."fileName", fi."contentPreview",
          fi."tagsJson", fi."indexedAt", fi."fileSizeBytes", fi."mimeType"
        FROM file_index fi
        LEFT JOIN document_embedding de ON de."fileIndexId" = fi.id
        WHERE ${whereConditions.join(" AND ")}
        ORDER BY hybrid_score DESC
        LIMIT \$$limitParamIndex
      ''';

      final rows = await session.db.unsafeQuery(
        searchQuery,
        parameters: QueryParameters.positional(parameters),
      );

      for (final row in rows) {
        final hybridScore = row[1] as double;
        results.add(
          AISearchResult(
            path: row[3] as String,
            fileName: row[4] as String,
            isDirectory: false,
            source: 'index',
            relevanceScore: hybridScore,
            contentPreview: row[5] as String?,
            foundVia: 'hybrid_semantic',
            matchReason:
                'Highly relevant hybrid match (${(hybridScore * 100).toStringAsFixed(0)}%)',
            fileSizeBytes: (row[8] as int?) ?? 0,
            mimeType: row[9] as String?,
            tags: _parseTags(row[6] as String?),
            indexedAt: row[7] as DateTime?,
          ),
        );
      }
    } catch (e) {
      session.log(
        'pgvector search failed in AISearchService: $e',
        level: LogLevel.warning,
      );
      // Fallback to text search if pgvector/embeddings fail
      return _fallbackSearch(session, query, limit, filters);
    }

    return results;
  }

  /// Fallback search using basic keyword matching
  Future<List<AISearchResult>> _fallbackSearch(
    Session session,
    String query,
    int limit,
    SearchFilters? filters,
  ) async {
    final results = <AISearchResult>[];

    final indexed = await FileIndex.db.find(
      session,
      where: (t) {
        var condition =
            t.fileName.ilike('%${query.replaceAll(' ', '%')}%') |
            t.contentPreview.ilike('%${query.replaceAll(' ', '%')}%');

        if (filters != null) {
          if (filters.dateFrom != null) {
            condition &= (t.indexedAt >= filters.dateFrom!);
          }
          if (filters.dateTo != null) {
            condition &= (t.indexedAt <= filters.dateTo!);
          }
          if (filters.minSize != null) {
            condition &= (t.fileSizeBytes >= filters.minSize!);
          }
          if (filters.maxSize != null) {
            condition &= (t.fileSizeBytes <= filters.maxSize!);
          }
          // Tags and types are harder with the basic 'where' builder on strings without more logic
          // but we'll stick to basic implementation for fallback
        }
        return condition;
      },
      limit: limit,
    );

    for (final doc in indexed) {
      results.add(
        AISearchResult(
          path: doc.path,
          fileName: doc.fileName,
          isDirectory: false,
          source: 'index',
          relevanceScore: 0.5,
          contentPreview: doc.contentPreview,
          foundVia: 'keyword_fallback',
          matchReason: 'Matched keyword search',
          fileSizeBytes: doc.fileSizeBytes,
          mimeType: doc.mimeType,
          tags: _parseTags(doc.tagsJson),
          indexedAt: doc.indexedAt,
        ),
      );
    }
    return results;
  }

  List<String> _parseTags(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return [];
    try {
      // It might be a comma-separated string or a JSON array
      if (tagsJson.startsWith('[')) {
        return List<String>.from(jsonDecode(tagsJson) as List);
      }
      return tagsJson.split(',').where((t) => t.isNotEmpty).toList();
    } catch (_) {
      return tagsJson.split(',').where((t) => t.isNotEmpty).toList();
    }
  }

  // ==========================================================================
  // RESULT RANKING
  // ==========================================================================

  /// Rank and deduplicate results
  List<AISearchResult> _rankResults(
    List<AISearchResult> results,
    String query,
  ) {
    // Remove duplicates by path
    final seen = <String>{};
    final unique = <AISearchResult>[];

    for (final result in results) {
      final normalizedPath = result.path.toLowerCase();
      if (!seen.contains(normalizedPath)) {
        seen.add(normalizedPath);
        unique.add(result);
      }
    }

    // Score and sort results
    final queryTerms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2);

    unique.sort((a, b) {
      // Prefer results found in both sources
      final aScore = _scoreResult(a, queryTerms);
      final bScore = _scoreResult(b, queryTerms);
      return bScore.compareTo(aScore);
    });

    return unique;
  }

  /// Score a single result for ranking
  double _scoreResult(AISearchResult result, Iterable<String> queryTerms) {
    var score = 0.0;

    // 1. Base score from relevance (if available from semantic search)
    // Semantic relevance is usually 0.0-1.0
    score += (result.relevanceScore ?? 0.3) * 1.5;

    // 2. Source Weighting
    if (result.source == 'index') {
      score += 0.2; // Prefer indexed (likely more relevant/processed)
    } else if (result.source == 'terminal') {
      score += 0.1;
    }

    // 3. Keyword Exactness (Lexical)
    final fileName = result.fileName.toLowerCase();
    for (final term in queryTerms) {
      final termLower = term.toLowerCase();
      if (fileName == termLower) {
        score += 1.0; // Exact match
      } else if (fileName.startsWith(termLower)) {
        score += 0.5; // Prefix match
      } else if (fileName.contains(termLower)) {
        score += 0.3; // Contains
      }
    }

    // 4. File Type Relevance (Bonus if it matches a pattern the AI extracted)
    // Note: We don't have the full intent here, but we can check common patterns
    if (result.mimeType != null) {
      // Small bonus for common document types if query looks like document search
      if (result.mimeType!.contains('pdf') ||
          result.mimeType!.contains('word')) {
        score += 0.05;
      }
    }

    // 5. Freshness Bonus (if indexedAt available)
    if (result.indexedAt != null) {
      final daysOld = DateTime.now().difference(result.indexedAt!).inDays;
      if (daysOld < 7) {
        score += 0.1; // Bonus for files indexed in the last week
      }
    }

    return score;
  }

  SearchFilters _buildFiltersFromIntent(SearchIntent intent) {
    final filters = SearchFilters();

    // Apply date range
    if (intent.dateRange != null) {
      if (intent.dateRange!.from != null) {
        filters.dateFrom = intent.dateRange!.from;
      }
      if (intent.dateRange!.to != null) {
        filters.dateTo = intent.dateRange!.to;
      }
    }

    // Apply size range
    if (intent.sizeRange != null) {
      if (intent.sizeRange!.minBytes != null) {
        filters.minSize = intent.sizeRange!.minBytes;
      }
      if (intent.sizeRange!.maxBytes != null) {
        filters.maxSize = intent.sizeRange!.maxBytes;
      }
    }

    // Note: Location paths and count expressions are not yet directly supported
    // in SearchFilters for pgvector search, but can be used in tool calling step later.

    // We could add logic to map content terms or file patterns to filters if needed
    // e.g. if filePatterns has *.pdf, add to filters.fileTypes

    if (intent.filePatterns.isNotEmpty) {
      // Extract extensions from patterns like *.pdf
      final exts = intent.filePatterns
          .where((p) => p.startsWith('*.'))
          .map((p) => p.substring(2))
          .toList();

      if (exts.isNotEmpty) {
        filters.fileTypes = exts;
      }
    }

    if (intent.contentSearchTerms.isNotEmpty) {
      filters.contentTerms = intent.contentSearchTerms;
    }

    // Apply location paths
    if (intent.locationPaths.isNotEmpty) {
      filters.locationPaths = intent.locationPaths;
    }

    // Apply count expression
    if (intent.countExpression != null) {
      filters.minCount = intent.countExpression!.minCount;
      filters.maxCount = intent.countExpression!.maxCount;
      filters.countUnit = intent.countExpression!.unit;
    }

    return filters;
  }

  DateType _parseDateType(String? type) {
    switch (type?.toUpperCase()) {
      case 'RELATIVE':
        return DateType.relative;
      case 'RANGE':
        return DateType.range;
      case 'ABSOLUTE':
      default:
        return DateType.absolute;
    }
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  SearchStrategy _determineStrategy(
    SearchStrategy requested,
    SearchIntent intent,
  ) {
    // If explicit strategy requested, use it
    if (requested != SearchStrategy.hybrid) {
      return requested;
    }

    // Otherwise, use intent-based strategy
    switch (intent.strategy) {
      case 'ai_only':
        return SearchStrategy.aiOnly;
      case 'semantic_first':
        return SearchStrategy.semanticFirst;
      default:
        return SearchStrategy.hybrid;
    }
  }

  Map<String, dynamic> _parseJson(String jsonStr) {
    try {
      return Map<String, dynamic>.from(
        (jsonStr.isEmpty ? {} : _jsonDecode(jsonStr)) as Map,
      );
    } catch (e) {
      return {};
    }
  }

  dynamic _jsonDecode(String source) {
    return jsonDecode(source);
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  /// Get all available drives as SearchPaths
  Future<List<SearchPath>> _getAvailableDrives() async {
    try {
      final drives = await _terminal.listDrives();
      return drives
          .map(
            (d) => SearchPath(
              path: d.path,
              description: d.description.isNotEmpty ? d.description : d.path,
              isDrive: true,
            ),
          )
          .toList();
    } catch (e) {
      // Fallback to root paths from CrossPlatformPaths
      final rootPaths = CrossPlatformPaths.rootPaths;
      return rootPaths
          .map(
            (p) => SearchPath(
              path: p,
              description: Platform.isWindows ? 'Drive ${p[0]}' : 'Root',
              isDrive: true,
            ),
          )
          .toList();
    }
  }

  /// Normalize a path for the current OS
  String _normalizePath(String path) {
    // Use the cross-platform utility
    return CrossPlatformPaths.normalize(CrossPlatformPaths.expand(path));
  }

  /// Get a user-friendly description for a path
  String _getLocationDescription(String path) {
    // Check against special folders
    final specialFolders = CrossPlatformPaths.specialFolders;
    final normalized = CrossPlatformPaths.normalize(path);

    for (final entry in specialFolders.entries) {
      final folderPath = CrossPlatformPaths.normalize(entry.value);
      if (normalized == folderPath ||
          normalized.startsWith(folderPath + CrossPlatformPaths.separator)) {
        // Return friendly name with subpath if present
        if (normalized != folderPath) {
          final subpath = normalized.substring(folderPath.length);
          return '${entry.key}${subpath.length > 20 ? '...' : subpath}';
        }
        return entry.key;
      }
    }

    // Check for home directory
    final home = CrossPlatformPaths.homeDirectory;
    if (normalized.startsWith(CrossPlatformPaths.normalize(home))) {
      final relative = CrossPlatformPaths.relative(home, path);
      return relative.isEmpty ? 'Home' : '~/$relative';
    }

    // Check if it's a drive or mount
    if (Platform.isWindows) {
      final drivePattern = RegExp(r'^[a-zA-Z]:\\?$');
      if (drivePattern.hasMatch(path)) {
        return 'Drive ${path[0].toUpperCase()}';
      }
    }

    return path;
  }

  /// Parse size with unit (e.g., "10 MB")
  static SizeExpression? _parseSizeWithUnit(RegExpMatch match) {
    final value = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = (match.group(2) ?? '').toUpperCase();

    final bytes = _convertToBytes(value, unit);
    if (bytes == null) return null;

    return SizeExpression(
      minBytes: bytes,
      maxBytes: (bytes * 1.2).round(),
      originalText: match.group(0),
    );
  }

  /// Parse comparative size (e.g., "larger than 10 MB")
  static SizeExpression? _parseComparativeSize(RegExpMatch match, bool isMin) {
    final valueStr = match.group(2) ?? match.group(3) ?? '0';
    final value = double.tryParse(valueStr) ?? 0;
    final unit = (match.group(3) ?? match.group(4) ?? '').toUpperCase();

    final bytes = _convertToBytes(value, unit);
    if (bytes == null) return null;

    if (isMin) {
      return SizeExpression(minBytes: bytes, originalText: match.group(0));
    } else {
      return SizeExpression(maxBytes: bytes, originalText: match.group(0));
    }
  }

  /// Convert size value to bytes
  static int? _convertToBytes(double value, String unit) {
    switch (unit.toUpperCase()) {
      case 'KB':
        return (value * 1024).round();
      case 'MB':
        return (value * 1024 * 1024).round();
      case 'GB':
        return (value * 1024 * 1024 * 1024).round();
      default:
        return null;
    }
  }
}

// =============================================================================
// SUPPORTING TYPES
// =============================================================================

/// Search intent parsed from user query
class SearchIntent {
  final String intent;
  final String strategy;
  final List<String> searchTerms;
  final List<String> filePatterns;
  final bool isFolderSearch;
  final String? reasoning;

  // New entity fields
  final DateExpression? dateRange;
  final SizeExpression? sizeRange;
  final List<String> locationPaths;
  final List<String> contentSearchTerms;
  final CountExpression? countExpression;

  SearchIntent({
    required this.intent,
    required this.strategy,
    required this.searchTerms,
    required this.filePatterns,
    required this.isFolderSearch,
    this.reasoning,
    this.dateRange,
    this.sizeRange,
    this.locationPaths = const [],
    this.contentSearchTerms = const [],
    this.countExpression,
  });
}

class DateExpression {
  final DateTime? from;
  final DateTime? to;
  final String? originalText;
  final DateType type;

  DateExpression({
    this.from,
    this.to,
    this.originalText,
    required this.type,
  });
}

enum DateType { absolute, relative, range }

class SizeExpression {
  final int? minBytes;
  final int? maxBytes;
  final String? originalText;

  SizeExpression({
    this.minBytes,
    this.maxBytes,
    this.originalText,
  });
}

class CountExpression {
  final int? minCount;
  final int? maxCount;
  final String? unit;

  CountExpression({
    this.minCount,
    this.maxCount,
    this.unit,
  });
}

/// Search strategy enum
enum SearchStrategy {
  /// Try semantic index first, fall back to AI terminal search
  semanticFirst,

  /// Skip index, use terminal commands only
  aiOnly,

  /// Run both in parallel, merge results
  hybrid,
}

/// Represents a path to search (drive or specific directory)
class SearchPath {
  final String path;
  final String description;
  final bool isDrive;

  SearchPath({
    required this.path,
    required this.description,
    this.isDrive = true,
  });
}

/// Cached search intent with expiration
class _CachedIntent {
  final SearchIntent intent;
  final DateTime cachedAt;

  _CachedIntent(this.intent) : cachedAt = DateTime.now();

  bool get isExpired {
    return DateTime.now().difference(cachedAt) >
        AISearchService._intentCacheTTL;
  }
}
