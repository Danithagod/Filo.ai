/// A simple utility to parse search queries with boolean operators (AND, OR, NOT)
/// and phrases into a structured format that can be used for SQL generation.
class QueryParser {
  /// Parse a query string into a list of query terms
  static ParsedQuery parse(String query) {
    if (query.trim().isEmpty) return ParsedQuery(terms: []);

    final terms = <QueryTerm>[];

    // Regular expression to handle:
    // 1. Double quoted phrases: "hello world"
    // 2. Terms with optional NOT operator: -term or NOT term
    // 3. Simple terms: term
    final regex = RegExp(r'(-|NOT\s+)?("([^"]*)"|(\S+))', caseSensitive: false);
    final matches = regex.allMatches(query);

    for (final match in matches) {
      final isNot = match.group(1) != null;
      final phraseMatch = match.group(3);
      final wordMatch = match.group(4);

      final text = (phraseMatch ?? wordMatch ?? '').trim();
      if (text.isEmpty) continue;

      // Handle explicit OR operator which might be its own match
      if (text.toUpperCase() == 'OR' && !isNot && phraseMatch == null) {
        if (terms.isNotEmpty) {
          terms.last.isOr = true;
        }
        continue;
      }

      terms.add(
        QueryTerm(
          text: text,
          isNot: isNot,
          isPhrase: phraseMatch != null,
        ),
      );
    }

    return ParsedQuery(terms: terms);
  }
}

class ParsedQuery {
  final List<QueryTerm> terms;

  ParsedQuery({required this.terms});

  /// Build a SQL condition and add parameters to the map
  /// Returns the SQL fragment, e.g. "(fi."fileName" ILIKE $4 AND NOT fi."fileName" ILIKE $5)"
  String buildSqlCondition({
    required String columnName,
    required List<dynamic> parameters,
    required int Function() nextParamIndex,
  }) {
    if (terms.isEmpty) return 'TRUE';

    final parts = <String>[];
    for (int i = 0; i < terms.length; i++) {
      final term = terms[i];
      final paramIdx = nextParamIndex();

      parameters.add('%${term.text}%');

      var cond = '${term.isNot ? "NOT " : ""}$columnName ILIKE \$$paramIdx';

      if (i > 0 && terms[i - 1].isOr) {
        parts.add('OR $cond');
      } else if (i > 0) {
        parts.add('AND $cond');
      } else {
        parts.add(cond);
      }
    }

    return '(${parts.join(" ")})';
  }
}

class QueryTerm {
  final String text;
  final bool isNot;
  final bool isPhrase;
  bool isOr = false;

  QueryTerm({
    required this.text,
    this.isNot = false,
    this.isPhrase = false,
  });
}
