import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/widgets/glass_container.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../models/biopsy_result.dart';
import '../services/chat_service.dart';
import '../widgets/formatted_ai_message_bubble.dart';

class AiChatScreen extends StatefulWidget {
  final UserProfile profile;
  final List<ChatMessage> initialHistory;
  final BiopsyResult? activeBiopsy;
  final Function(List<ChatMessage>) onHistoryUpdated;
  final VoidCallback onNavigateToBiopsy;
  final VoidCallback onNewChat;

  const AiChatScreen({
    super.key,
    required this.profile,
    required this.initialHistory,
    this.activeBiopsy,
    required this.onHistoryUpdated,
    required this.onNavigateToBiopsy,
    required this.onNewChat,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  late List<ChatMessage> _messages;
  bool _isTyping = false;
  Map<String, dynamic>? _activeBiopsyData;
  String? _lastAttachedBiopsyId;
  String _currentResponseStyle = 'easy';

  final List<Map<String, dynamic>> _styleOptions = [
    {'id': 'easy', 'label': '💡 Easy / Patient', 'desc': 'Concise & patient-friendly'},
    {'id': 'bullet', 'label': '📋 Bullet Points', 'desc': 'Checklists & structured bullets'},
    {'id': 'cards', 'label': '📊 Visual Cards', 'desc': 'Structured color-coded cards'},
    {'id': 'detailed', 'label': '🩺 Deep Clinical', 'desc': 'Full 5-category medical analysis'},
  ];

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.initialHistory);
    _currentResponseStyle = _chatService.responseStyle;

    if (widget.activeBiopsy != null) {
      _lastAttachedBiopsyId = widget.activeBiopsy!.id;
      final metricsJson = <String, dynamic>{};
      widget.activeBiopsy!.metrics.forEach((k, v) {
        metricsJson[k] = '${v.name}: ${v.isPositive ? "DETECTED" : "NOT DETECTED"} (${v.probability.toStringAsFixed(1)}%)';
      });
      _activeBiopsyData = metricsJson;

      // Automatically trigger interpretation if arriving with a fresh biopsy not already discussed
      final bool alreadyDiscussed = _messages.any((m) => m.text.contains(widget.activeBiopsy!.id));
      if (!alreadyDiscussed) {
        Future.microtask(() => _sendMessage('Interpret my histology biopsy scan findings (ID: ${widget.activeBiopsy!.id}).'));
      }
    }
  }

  void _onStyleChanged(String newStyle) {
    setState(() {
      _currentResponseStyle = newStyle;
    });
    _chatService.configure(responseStyle: newStyle);
  }

  @override
  void didUpdateWidget(covariant AiChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeBiopsy != null && widget.activeBiopsy!.id != _lastAttachedBiopsyId) {
      _lastAttachedBiopsyId = widget.activeBiopsy!.id;
      final metricsJson = <String, dynamic>{};
      widget.activeBiopsy!.metrics.forEach((k, v) {
        metricsJson[k] = '${v.name}: ${v.isPositive ? "DETECTED" : "NOT DETECTED"} (${v.probability.toStringAsFixed(1)}%)';
      });
      setState(() {
        _activeBiopsyData = metricsJson;
      });
      
      // Automatically trigger interpretation for the new biopsy
      Future.microtask(() => _sendMessage('Interpret my new biopsy scan findings (ID: ${widget.activeBiopsy!.id}).'));
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: cleanText,
      isUser: true,
      timestamp: DateTime.now(),
      biopsyData: _activeBiopsyData,
    );

    setState(() {
      _messages.add(userMsg);
      _inputController.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        userMessage: cleanText,
        history: _messages,
        profile: widget.profile,
        biopsyData: _activeBiopsyData,
      );

      setState(() {
        _messages.add(response);
        _isTyping = false;
      });
      widget.onHistoryUpdated(_messages);
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: 'err_${DateTime.now().millisecondsSinceEpoch}',
            text: 'I encountered an error processing your query: $e',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages = [];
    });
    widget.onNewChat();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    final lastMsg = _messages.isNotEmpty ? _messages.last : null;
    final currentSuggestions = (lastMsg != null && !lastMsg.isUser && lastMsg.suggestions != null)
        ? lastMsg.suggestions!
        : ChatService.initialSuggestions;

    return Column(
      children: [
        // ── Top Bar: New Chat & Format Style Switcher ───────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Style Selector Pills Bar
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _styleOptions.map((opt) {
                      final isSelected = _currentResponseStyle == opt['id'];
                      return GestureDetector(
                        onTap: () => _onStyleChanged(opt['id'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: isDark ? 0.25 : 0.18)
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? accent : (isDark ? Colors.white12 : Colors.black12),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            opt['label'] as String,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? accent : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: _clearChat,
                icon: const Icon(Icons.add_comment_outlined, size: 13),
                label: const Text('New Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),


        // ── Active Biopsy Context Bar ───────────────────────────
        if (_activeBiopsyData != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(Icons.biotech, size: 16, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Active Biopsy Scan Findings Attached to Chat Context',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _activeBiopsyData = null),
                  child: const Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ],
            ),
          ),

        // ── Message Stream List ────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isTyping) {
                return _buildTypingIndicator(accent, isDark);
              }
              final msg = _messages[index];
              return _buildMessageBubble(msg, accent, isDark);
            },
          ),
        ),

        // ── Suggestion Chips Horizontal Bar ────────────────────
        if (!_isTyping && currentSuggestions.isNotEmpty)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: currentSuggestions.length,
              itemBuilder: (context, i) {
                final chipText = currentSuggestions[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      chipText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    side: BorderSide(
                      color: accent.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () => _sendMessage(chipText),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 6),

        Container(
          padding: EdgeInsets.fromLTRB(14, 4, 14, MediaQuery.of(context).padding.bottom + 100),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.biotech_outlined,
                    color: accent.withValues(alpha: 0.8),
                    size: 22,
                  ),
                  onPressed: widget.onNavigateToBiopsy,
                  tooltip: 'Attach Biopsy Scan',
                ),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Message LiverAI...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 18,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  onPressed: () => _sendMessage(_inputController.text),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, Color accent, bool isDark) {
    final timeStr = DateFormat('hh:mm a').format(msg.timestamp);

    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.85)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [accent, const Color(0xFF6366F1)]),
              ),
              child: Center(
                child: Text(
                  widget.profile.name.isNotEmpty ? widget.profile.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Message Bubble (Multi-Format Formatted Bubble)
    return FormattedAiMessageBubble(
      message: msg,
      accent: accent,
      isDark: isDark,
      timeStr: timeStr,
      onCopy: _copyToClipboard,
    );
  }

  Widget _buildTypingIndicator(Color accent, bool isDark) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
            ),
            child: Icon(Icons.favorite, size: 16, color: accent),
          ),
          const SizedBox(width: 10),
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                ),
                const SizedBox(width: 10),
                Text(
                  'LiverAI is thinking...',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
