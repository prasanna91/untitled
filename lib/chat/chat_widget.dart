import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/gestures.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'chat_message.dart';
import 'chat_service.dart';
import 'search_result_model.dart';
import 'dart:convert';
import 'voice_input_card.dart';

class ChatWidget extends StatefulWidget {
  final InAppWebViewController webViewController;
  final String currentUrl;
  final Function(bool) onVisibilityChanged;

  const ChatWidget({
    super.key,
    required this.webViewController,
    required this.currentUrl,
    required this.onVisibilityChanged,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> with TickerProviderStateMixin {
  late final ChatService _chatService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isLoading = false;
  bool _isListening = false;
  bool _showVoiceCard = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(widget.currentUrl);
    _chatService.chatStream.listen((_) {
      _scrollToBottom();
    });
    _initSpeech();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      );
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Speech recognition not available'),
            backgroundColor: Colors.orange.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Speech initialization error: $e');
    }
  }

  Future<void> _startListening() async {
    try {
      if (!_isListening) {
        bool available = await _speech.initialize();
        if (available) {
          setState(() {
            _isListening = true;
            _showVoiceCard = true;
          });
          _pulseController.repeat();
          await _speech.listen(
            onResult: (result) {
              setState(() {
                _messageController.text = result.recognizedWords;
                if (result.finalResult) {
                  _isListening = false;
                  _pulseController.stop();
                  if (_messageController.text.isNotEmpty) {
                    _showVoiceCard = false;
                  }
                }
              });
            },
          );
        }
      } else {
        setState(() {
          _isListening = false;
          _showVoiceCard = false;
        });
        _pulseController.stop();
        _speech.stop();
      }
    } catch (e) {
      setState(() {
        _isListening = false;
        _showVoiceCard = false;
      });
      _pulseController.stop();
      debugPrint('Speech recognition error: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    _speech.stop();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (mounted && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleSend() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() => _isLoading = true);

    try {
      await _chatService.processUserMessage(message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLinkTap(String url,
      {List<String>? highlightKeywords}) async {
    try {
      // Validate URL
      if (url.isEmpty) {
        throw Exception('URL is empty');
      }

      // Ensure URL has proper scheme
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      debugPrint('🔄 Loading URL: $url');
      debugPrint('🔗 Original URL before processing: ${url}');
      debugPrint('🔗 WebView controller state: Valid');

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Loading page...',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF667eea),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 10),
          ),
        );
      }

      // Simplified WebView controller validation
      debugPrint('🔄 Attempting to load URL: $url');

      // Direct URL loading without complex validation
      await widget.webViewController.loadUrl(
        urlRequest: URLRequest(url: WebUri(url)),
      );

      debugPrint('✅ URL loaded successfully: $url');

      // Wait for page to load before highlighting
      await Future.delayed(const Duration(milliseconds: 2000));

      if (highlightKeywords != null && highlightKeywords.isNotEmpty) {
        debugPrint('🎯 Highlighting keywords: $highlightKeywords');

        // Try highlighting with multiple attempts and better error handling
        bool highlightSuccess = false;
        for (int i = 0; i < 3; i++) {
          try {
            await Future.delayed(Duration(milliseconds: 1000 * (i + 1)));

            final js = '''
              function highlightKeywords(keywords) {
                try {
                  console.log('Attempt ${i + 1}: Highlighting keywords:', keywords);
                  
                  // Remove existing highlights
                  const existingHighlights = document.querySelectorAll('.keyword-highlight');
                  existingHighlights.forEach(el => {
                    const parent = el.parentNode;
                    if (parent) {
                      parent.insertBefore(el.firstChild, el);
                      parent.removeChild(el);
                    }
                  });
                  
                  const body = document.body;
                  if (!body) {
                    console.log('Body not found, page may not be loaded');
                    return false;
                  }
                  
                  const walker = document.createTreeWalker(
                    body, 
                    NodeFilter.SHOW_TEXT,
                    null,
                    false
                  );
                  
                  const matches = [];
                  let node;
                  let firstMatch = null;
                  
                  while (node = walker.nextNode()) {
                    const text = node.textContent;
                    const lowerText = text.toLowerCase();
                    
                    for (const keyword of keywords) {
                      const lowerKeyword = keyword.toLowerCase();
                      if (lowerText.includes(lowerKeyword)) {
                        matches.push({node: node, keyword: keyword});
                        if (!firstMatch) firstMatch = node;
                        break;
                      }
                    }
                  }
                  
                  if (matches.length === 0) {
                    console.log('No keyword matches found');
                    return false;
                  }
                  
                  console.log('Found ' + matches.length + ' keyword matches');
                  
                  // Scroll to first match - Fixed to handle different node types
                  if (firstMatch) {
                    try {
                      // Try to find a scrollable parent element
                      let scrollTarget = firstMatch;
                      while (scrollTarget && scrollTarget !== body) {
                        if (scrollTarget.scrollIntoView) {
                          scrollTarget.scrollIntoView({
                            behavior: 'smooth',
                            block: 'center'
                          });
                          break;
                        }
                        scrollTarget = scrollTarget.parentElement;
                      }
                    } catch (scrollError) {
                      console.log('Scroll error:', scrollError);
                      // Continue without scrolling
                    }
                  }
                  
                  matches.forEach(({node, keyword}) => {
                    const text = node.textContent;
                    const lowerText = text.toLowerCase();
                    const lowerKeyword = keyword.toLowerCase();
                    const startIndex = lowerText.indexOf(lowerKeyword);
                    
                    if (startIndex !== -1) {
                      const beforeText = text.substring(0, startIndex);
                      const matchedText = text.substring(startIndex, startIndex + keyword.length);
                      const afterText = text.substring(startIndex + keyword.length);
                      
                      const span = document.createElement('span');
                      span.className = 'keyword-highlight';
                      span.style.backgroundColor = '#FFEB3B';
                      span.style.color = '#000000';
                      span.style.fontWeight = 'bold';
                      span.style.padding = '2px 4px';
                      span.style.borderRadius = '3px';
                      span.style.boxShadow = '0 2px 4px rgba(0,0,0,0.2)';
                      span.textContent = matchedText;
                      
                      const parent = node.parentNode;
                      if (parent) {
                        const textNode = document.createTextNode(beforeText);
                        const afterNode = document.createTextNode(afterText);
                        
                        parent.insertBefore(textNode, node);
                        parent.insertBefore(span, node);
                        parent.insertBefore(afterNode, node);
                        parent.removeChild(node);
                      }
                    }
                  });
                  
                  return true;
                } catch (error) {
                  console.error('Error in highlightKeywords:', error);
                  return false;
                }
              }
              
              highlightKeywords(${jsonEncode(highlightKeywords)});
            ''';

            final result =
                await widget.webViewController.evaluateJavascript(source: js);

            if (result == true) {
              debugPrint('✅ Keywords highlighted successfully');
              highlightSuccess = true;
              break;
            } else {
              debugPrint('⚠️ Highlighting attempt ${i + 1} failed');
            }
          } catch (e) {
            debugPrint('❌ Error during highlighting attempt ${i + 1}: $e');
          }
        }

        if (highlightSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      CupertinoIcons.check_mark,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Keywords highlighted on page',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade400,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      CupertinoIcons.info,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Page loaded but keywords not found',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange.shade400,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _handleLinkTap: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.toString().contains('WebView has crashed')
                        ? 'WebView crashed. Please try again.'
                        : 'Failed to load page: ${e.toString()}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Curves.easeOutCubic,
        )),
        child: Stack(
          children: [
            Center(
              child: Container(
                width: size.width * 0.95,
                height: size.height * 0.9,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: _buildChatList(),
                        ),
                        _buildInputArea(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_showVoiceCard)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: VoiceInputCard(
                    isListening: _isListening,
                    recognizedText: _messageController.text,
                    onClose: () {
                      setState(() {
                        _isListening = false;
                        _showVoiceCard = false;
                      });
                      _pulseController.stop();
                      _speech.stop();
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getCleanHost(Uri uri) {
    final host = uri.host;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.chat_bubble_2_fill,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Powered by ${_getCleanHost(Uri.parse(widget.currentUrl))}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.delete, color: Colors.white),
                  onPressed: () async {
                    await _chatService.clearHistory();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Chat history cleared'),
                          backgroundColor: Colors.green.shade400,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  tooltip: 'Clear Chat',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
                  onPressed: () => widget.onVisibilityChanged(false),
                  tooltip: 'Close Chat',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.chatStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.chat_bubble_2,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Start a conversation!',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask me anything about this website',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final bubbleColor = isUser ? const Color(0xFF667eea) : Colors.grey.shade100;
    final textColor = isUser ? Colors.white : Colors.black87;
    final alignment =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_crop_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 8),
                      bottomRight: Radius.circular(isUser ? 8 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Only show text if there are no search results
                      if (message.searchResults == null ||
                          message.searchResults!.isEmpty)
                        SelectableText.rich(
                          TextSpan(
                            children: _parseMessageText(message.text),
                          ),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      if (message.searchResults != null &&
                          message.searchResults!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...message.searchResults!.map((result) =>
                            _buildSearchResultCard(result, message, textColor)),
                      ],
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Icon(
                  CupertinoIcons.time,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _parseMessageText(String text) {
    final spans = <InlineSpan>[];
    final linkPattern = RegExp(r'\[(.*?)\]\((.*?)\)');
    final boldPattern = RegExp(r'\*\*(.*?)\*\*');

    var currentIndex = 0;

    while (currentIndex < text.length) {
      // Try to find the next markdown element
      final linkMatch = linkPattern.firstMatch(text.substring(currentIndex));
      final boldMatch = boldPattern.firstMatch(text.substring(currentIndex));

      // Find which comes first
      final linkStart = linkMatch?.start ?? text.length;
      final boldStart = boldMatch?.start ?? text.length;

      if (linkStart < boldStart) {
        // Add text before the link
        if (linkStart > 0) {
          spans.add(TextSpan(
            text: text.substring(currentIndex, currentIndex + linkStart),
          ));
        }

        // Add the link
        spans.add(TextSpan(
          text: linkMatch![1],
          style: TextStyle(
            color: Colors.white,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _handleLinkTap(linkMatch[2]!),
        ));

        currentIndex += linkMatch.end;
      } else if (boldStart < text.length) {
        // Add text before the bold
        if (boldStart > 0) {
          spans.add(TextSpan(
            text: text.substring(currentIndex, currentIndex + boldStart),
          ));
        }

        // Add the bold text
        spans.add(TextSpan(
          text: boldMatch![1],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ));

        currentIndex += boldMatch.end;
      } else {
        // Add remaining text
        spans.add(TextSpan(
          text: text.substring(currentIndex),
        ));
        break;
      }
    }

    return spans;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Future<void> _handleUrl(String url, {List<String>? highlightKeywords}) async {
    debugPrint('🚀 _handleUrl called with URL: $url');
    debugPrint('🚀 Highlight keywords: $highlightKeywords');
    await _handleLinkTap(url, highlightKeywords: highlightKeywords);
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Microphone Button with Pulse Animation
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: Colors.red.withValues(
                                alpha: 0.3 - (_pulseController.value * 0.3)),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _startListening,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.red.shade400
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isListening
                              ? Colors.red.shade300
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _isListening
                            ? CupertinoIcons.mic_fill
                            : CupertinoIcons.mic,
                        color:
                            _isListening ? Colors.white : Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Text Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'Listening...'
                            : 'Type your message...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  // Send Button
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _isLoading ? null : _handleSend,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2)
                                    ],
                                  ),
                            color: _isLoading ? Colors.grey.shade300 : null,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _isLoading
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF667eea)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey),
                                  ),
                                )
                              : const Icon(
                                  CupertinoIcons.arrow_up,
                                  color: Colors.white,
                                  size: 18,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(
      SearchResult result, ChatMessage message, Color textColor) {
    final relevance = (result.relevance * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRelevanceColor(relevance).withValues(alpha: 0.15),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title (bold, not a link)
            Text(
              result.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF2D3748),
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Content: Just two lines as requested
            Text(
              result.content,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5568),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Small relevance indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getRelevanceColor(relevance).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$relevance% match',
                    style: TextStyle(
                      fontSize: 11,
                      color: _getRelevanceColor(relevance),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                // 'View more' link - Made more prominent
                GestureDetector(
                  onTap: () {
                    debugPrint('🔗 View more tapped: ${result.url}');
                    debugPrint('🔗 Title: ${result.title}');

                    // Get keywords for highlighting
                    final keywords = <String>[];
                    if (result.metadata.containsKey('keyword') &&
                        result.metadata['keyword'] != null &&
                        result.metadata['keyword'].toString().isNotEmpty) {
                      keywords.add(result.metadata['keyword'].toString());
                    }
                    if (message.keywords != null) {
                      keywords.addAll(message.keywords!);
                    }
                    final uniqueKeywords = keywords.toSet().toList();
                    debugPrint('🔗 Keywords for highlighting: $uniqueKeywords');

                    _handleUrl(result.url, highlightKeywords: uniqueKeywords);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF667eea).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View more',
                          style: const TextStyle(
                            color: Color(0xFF667eea),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new,
                          size: 12,
                          color: Color(0xFF667eea),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRelevanceColor(int relevance) {
    if (relevance >= 80) return const Color(0xFF48BB78); // 🟢 Green - Excellent
    if (relevance >= 60) return const Color(0xFFECC94B); // 🟡 Yellow - Good
    if (relevance >= 40) return const Color(0xFFED8936); // 🟠 Orange - Moderate
    return const Color(0xFFE53E3E); // 🔴 Red - Low
  }
}
