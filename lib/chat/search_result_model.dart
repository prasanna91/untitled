class SearchResult {
  final String title;
  final String content;
  final String url;
  final Map<String, dynamic> metadata;
  final String favicon;
  final double relevance;

  SearchResult({
    required this.title,
    required this.content,
    required this.url,
    required this.metadata,
    required this.favicon,
    this.relevance = 0.0,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      url: json['url'] ?? '',
      favicon: json['favicon'] ?? '',
      metadata: json['metadata'] ?? {},
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'url': url,
      'favicon': favicon,
      'metadata': metadata,
      'relevance': relevance,
    };
  }

  // Get the matched keyword from metadata
  String get matchedKeyword => metadata['keyword'] as String? ?? '';

  // Get the matched tag type (h1, h2, p, etc.)
  String get matchedTag => metadata['matchedTag'] as String? ?? '';

  // Get the page title
  String get pageTitle => metadata['pageTitle'] as String? ?? '';

  // Get the domain
  String get domain => metadata['domain'] as String? ?? '';

  // Get relevance score as percentage
  String get relevancePercentage => '${(relevance * 100).round()}%';

  // Check if this is a high relevance result
  bool get isHighRelevance => relevance > 0.7;

  // Check if this is a medium relevance result
  bool get isMediumRelevance => relevance > 0.4 && relevance <= 0.7;

  // Get relevance color for UI
  int get relevanceColor {
    if (relevance > 0.8) return 0xFF4CAF50; // Green for high relevance
    if (relevance > 0.6) return 0xFFFF9800; // Orange for medium relevance
    return 0xFF9E9E9E; // Grey for low relevance
  }
}

// class SearchResult {
//   final String title;
//   final String url;
//   final String favicon;
//
//   SearchResult({
//     required this.title,
//     required this.url,
//     required this.favicon,
//   });
//
//   factory SearchResult.fromJson(Map<String, dynamic> json) {
//     return SearchResult(
//       title: json['title'] ?? '',
//       url: json['url'] ?? '',
//       favicon: json['favicon'] ?? '',
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'title': title,
//       'url': url,
//       'favicon': favicon,
//     };
//   }
// }
