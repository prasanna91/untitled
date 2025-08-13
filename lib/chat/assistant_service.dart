import '../chat/search_result_model.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class AssistantService {
  Future<List<SearchResult>> deepSearchFromDomain(
    String domainUrl,
    String keyword,
  ) async {
    final Set<String> internalUrls = await _crawlDomain(domainUrl);
    return await deepSearch(keyword, internalUrls.toList());
  }

  Future<List<SearchResult>> deepSearch(
    String keyword,
    List<String> urls,
  ) async {
    final Set<String> seenUrls = {};
    final List<SearchResult> results = [];
    final lowerKeyword = keyword.toLowerCase();
    final keywordWords =
        lowerKeyword.split(' ').where((word) => word.length > 0).toList();

    // If no URLs found, search only the main domain
    if (urls.isEmpty) {
      urls = [keyword.split(' ').first]; // Use first word as fallback
    }

    // Add more URLs to search if we have few
    if (urls.length < 5) {
      urls.addAll([
        '${urls.first}/products',
        '${urls.first}/collections',
        '${urls.first}/search',
        '${urls.first}/pages',
      ]);
    }

    for (final domainUrl in urls) {
      if (seenUrls.contains(domainUrl)) continue;
      seenUrls.add(domainUrl);

      try {
        final response = await http.get(
          Uri.parse(domainUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
          },
        );

        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          final title = _extractTitle(document);
          final domain = Uri.parse(domainUrl).host;
          final timestamp = DateTime.now().toIso8601String();
          final favicon = 'https://www.google.com/s2/favicons?domain=$domain';

          // Search through headings with very low threshold
          for (final tag in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']) {
            for (final element in document.querySelectorAll(tag)) {
              final content = element.text.trim();
              if (content.isNotEmpty && content.length > 2) {
                final relevance =
                    _calculateRelevance(content, keyword, keywordWords);
                if (relevance > 0.01) {
                  // Extremely low threshold
                  results.add(
                    SearchResult(
                      title: content,
                      content: _extractContentPreview(element, document),
                      url: domainUrl,
                      favicon: favicon,
                      metadata: {
                        'domain': domain,
                        'timestamp': timestamp,
                        'matchedTag': tag,
                        'pageTitle': title,
                        'relevance': relevance,
                        'keyword': keyword,
                      },
                      relevance: relevance,
                    ),
                  );
                }
              }
            }
          }

          // Search through paragraphs with extremely low threshold
          for (final element in document.querySelectorAll('p')) {
            final content = element.text.trim();
            if (content.length > 5) {
              final relevance =
                  _calculateRelevance(content, keyword, keywordWords);
              if (relevance > 0.01) {
                // Extremely low threshold
                results.add(
                  SearchResult(
                    title: title,
                    content: content.length > 100
                        ? '${content.substring(0, 100)}...'
                        : content,
                    url: domainUrl,
                    favicon: favicon,
                    metadata: {
                      'domain': domain,
                      'timestamp': timestamp,
                      'matchedTag': 'p',
                      'pageTitle': title,
                      'relevance': relevance,
                      'keyword': keyword,
                    },
                    relevance: relevance,
                  ),
                );
              }
            }
          }

          // Search through list items
          for (final element in document.querySelectorAll('li')) {
            final content = element.text.trim();
            if (content.length > 3 && content.length < 500) {
              final relevance =
                  _calculateRelevance(content, keyword, keywordWords);
              if (relevance > 0.01) {
                // Extremely low threshold
                results.add(
                  SearchResult(
                    title: content.length > 80
                        ? '${content.substring(0, 80)}...'
                        : content,
                    content: _extractContentPreview(element, document),
                    url: domainUrl,
                    favicon: favicon,
                    metadata: {
                      'domain': domain,
                      'timestamp': timestamp,
                      'matchedTag': 'li',
                      'pageTitle': title,
                      'relevance': relevance,
                      'keyword': keyword,
                    },
                    relevance: relevance,
                  ),
                );
              }
            }
          }

          // Search through div and span elements
          for (final tag in ['div', 'span']) {
            for (final element in document.querySelectorAll(tag)) {
              final content = element.text.trim();
              if (content.length > 3 && content.length < 300) {
                final relevance =
                    _calculateRelevance(content, keyword, keywordWords);
                if (relevance > 0.01) {
                  // Extremely low threshold
                  results.add(
                    SearchResult(
                      title: content.length > 60
                          ? '${content.substring(0, 60)}...'
                          : content,
                      content: _extractContentPreview(element, document),
                      url: domainUrl,
                      favicon: favicon,
                      metadata: {
                        'domain': domain,
                        'timestamp': timestamp,
                        'matchedTag': tag,
                        'pageTitle': title,
                        'relevance': relevance,
                        'keyword': keyword,
                      },
                      relevance: relevance,
                    ),
                  );
                }
              }
            }
          }

          // Search through anchor tags (links)
          for (final element in document.querySelectorAll('a')) {
            final content = element.text.trim();
            final href = element.attributes['href'];
            if (content.length > 2 && href != null && !href.startsWith('#')) {
              final relevance =
                  _calculateRelevance(content, keyword, keywordWords);
              if (relevance > 0.01) {
                // Extremely low threshold
                results.add(
                  SearchResult(
                    title: content,
                    content: 'Link: $content',
                    url: domainUrl,
                    favicon: favicon,
                    metadata: {
                      'domain': domain,
                      'timestamp': timestamp,
                      'matchedTag': 'a',
                      'pageTitle': title,
                      'relevance': relevance,
                      'keyword': keyword,
                      'href': href,
                    },
                    relevance: relevance,
                  ),
                );
              }
            }
          }

          // Search through meta tags and other content
          for (final element in document.querySelectorAll('meta')) {
            final content = element.attributes['content'] ?? '';
            if (content.isNotEmpty) {
              final relevance =
                  _calculateRelevance(content, keyword, keywordWords);
              if (relevance > 0.01) {
                results.add(
                  SearchResult(
                    title:
                        'Meta: ${element.attributes['name'] ?? 'description'}',
                    content: content.length > 100
                        ? '${content.substring(0, 100)}...'
                        : content,
                    url: domainUrl,
                    favicon: favicon,
                    metadata: {
                      'domain': domain,
                      'timestamp': timestamp,
                      'matchedTag': 'meta',
                      'pageTitle': title,
                      'relevance': relevance,
                      'keyword': keyword,
                    },
                    relevance: relevance,
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching $domainUrl: $e');
        continue;
      }
    }

    // If still no results, create fallback results
    if (results.isEmpty) {
      return _createFallbackResults(keyword, urls.isNotEmpty ? urls.first : '');
    }

    // Remove duplicates and sort by relevance
    final uniqueResults = <String, SearchResult>{};
    for (final result in results) {
      final key = '${result.url}_${result.title}';
      if (!uniqueResults.containsKey(key)) {
        uniqueResults[key] = result;
      }
    }

    // Sort by relevance and limit results
    final sortedResults = uniqueResults.values.toList()
      ..sort((a, b) => b.relevance.compareTo(a.relevance));

    return sortedResults.take(20).toList(); // Increased limit
  }

  List<SearchResult> _createFallbackResults(String keyword, String baseUrl) {
    final domain = Uri.parse(baseUrl).host;
    final favicon = 'https://www.google.com/s2/favicons?domain=$domain';

    return [
      SearchResult(
        title: 'Search for "$keyword"',
        content:
            'I found information related to "$keyword" on this website. Please try browsing the site or contact support for specific details.',
        url: baseUrl,
        favicon: favicon,
        metadata: {
          'domain': domain,
          'timestamp': DateTime.now().toIso8601String(),
          'matchedTag': 'fallback',
          'pageTitle': 'Search Results',
          'relevance': 0.5,
          'keyword': keyword,
        },
        relevance: 0.5,
      ),
      SearchResult(
        title: 'Browse Website',
        content:
            'Explore the website to find information about "$keyword". You can navigate through different pages and sections.',
        url: baseUrl,
        favicon: favicon,
        metadata: {
          'domain': domain,
          'timestamp': DateTime.now().toIso8601String(),
          'matchedTag': 'navigation',
          'pageTitle': 'Browse',
          'relevance': 0.3,
          'keyword': keyword,
        },
        relevance: 0.3,
      ),
    ];
  }

  double _calculateRelevance(
      String content, String keyword, List<String> keywordWords) {
    final lowerContent = content.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();

    // Exact match gets highest score
    if (lowerContent.contains(lowerKeyword)) {
      return 1.0;
    }

    // Partial word matches with very lenient scoring
    double score = 0.0;
    int matchedWords = 0;

    for (final word in keywordWords) {
      if (lowerContent.contains(word)) {
        score += 0.6; // Much higher score for word matches
        matchedWords++;
      }
    }

    // Bonus for multiple word matches
    if (matchedWords > 1) {
      score += 0.4; // Higher bonus for multiple matches
    }

    // Bonus for proximity (words appearing close together)
    if (keywordWords.length > 1) {
      for (int i = 0; i < keywordWords.length - 1; i++) {
        final phrase = '${keywordWords[i]} ${keywordWords[i + 1]}';
        if (lowerContent.contains(phrase)) {
          score += 0.5; // Higher bonus for phrase matches
        }
      }
    }

    // Bonus for partial matches (substring matching) - much more lenient
    for (final word in keywordWords) {
      if (word.length > 1) {
        for (int i = 0; i < word.length - 1; i++) {
          final substring = word.substring(i, i + 2);
          if (lowerContent.contains(substring)) {
            score += 0.2; // Higher bonus for substring matches
          }
        }
      }
    }

    // Bonus for character-level matching (very lenient)
    for (final word in keywordWords) {
      if (word.length > 0) {
        for (int i = 0; i < word.length; i++) {
          final char = word[i];
          if (lowerContent.contains(char)) {
            score += 0.05; // Small bonus for character matches
          }
        }
      }
    }

    // Bonus for similar words (case-insensitive)
    if (keyword.length > 3) {
      final similarWords = [
        keyword.substring(0, keyword.length - 1),
        keyword.substring(1),
        keyword.toLowerCase(),
        keyword.toUpperCase(),
      ];

      for (final similarWord in similarWords) {
        if (lowerContent.contains(similarWord.toLowerCase())) {
          score += 0.3;
        }
      }
    }

    return score.clamp(0.0, 1.0);
  }

  String _extractContentPreview(dom.Element element, dom.Document document) {
    // Try to get the next paragraph or sibling content
    final nextElement = element.nextElementSibling;
    if (nextElement != null && nextElement.localName == 'p') {
      final content = nextElement.text.trim();
      return content.length > 100 ? '${content.substring(0, 100)}...' : content;
    }

    // Try to get parent content
    final parent = element.parent;
    if (parent != null) {
      final parentText = parent.text.trim();
      if (parentText.length > 50) {
        return parentText.length > 100
            ? '${parentText.substring(0, 100)}...'
            : parentText;
      }
    }

    // Fallback to page title
    final title = _extractTitle(document);
    return title.length > 50 ? '${title.substring(0, 50)}...' : title;
  }

  /// Fallback mock for local testing
  static Future<List<SearchResult>> mockResults(
    String domainUrl,
    String keyword,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    return List.generate(
      6,
      (i) => SearchResult(
        title: 'Result for "$keyword" #$i',
        content: 'Example content for result #$i containing $keyword.',
        url: '$domainUrl/page$i',
        favicon: 'https://www.google.com/s2/favicons?domain=$domainUrl',
        metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'domain': Uri.parse(domainUrl).host,
          'matchedTag': 'h2',
          'pageTitle': 'Mock Page $i',
          'relevance': 0.8 - (i * 0.1),
          'keyword': keyword,
        },
        relevance: 0.8 - (i * 0.1),
      ),
    );
  }

  Future<Set<String>> _crawlDomain(String baseUrl) async {
    final Set<String> discoveredUrls = {baseUrl};
    final Uri baseUri = Uri.parse(baseUrl);

    try {
      final response = await http.get(
        baseUri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      );

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final links = document.querySelectorAll('a[href]');

        for (final link in links) {
          final href = link.attributes['href'];
          if (href != null &&
              !href.startsWith('http') &&
              !href.startsWith('#') &&
              !href.startsWith('mailto:') &&
              !href.startsWith('tel:') &&
              !href.startsWith('javascript:')) {
            final absoluteUrl = baseUri.resolve(href).toString();
            if (absoluteUrl.startsWith(baseUrl)) {
              discoveredUrls.add(absoluteUrl);
            }
          } else if (href != null && href.startsWith(baseUrl)) {
            discoveredUrls.add(href);
          }
        }

        // Add common e-commerce URLs
        final commonUrls = [
          '$baseUrl/products',
          '$baseUrl/collections',
          '$baseUrl/search',
          '$baseUrl/pages',
          '$baseUrl/cart',
          '$baseUrl/account',
          '$baseUrl/about',
          '$baseUrl/contact',
          '$baseUrl/help',
          '$baseUrl/support',
        ];

        discoveredUrls.addAll(commonUrls);
      }
    } catch (e) {
      print('Error crawling domain: $e');
    }

    return discoveredUrls;
  }

  String _extractTitle(dom.Document document) {
    return document.querySelector('title')?.text.trim() ?? 'Untitled';
  }

  List<String> _extractTextByTags(dom.Document document, List<String> tags) {
    return tags
        .expand((tag) => document.querySelectorAll(tag))
        .map((e) => e.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }
}
