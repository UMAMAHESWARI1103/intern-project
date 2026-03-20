import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ── Chat message model ────────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  bool isLoading;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
  }) : time = DateTime.now();
}

// ── Groq API service ──────────────────────────────────────────────────────────
class _GroqService {
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY'); // ✅ Safe - no hardcoded key
  static const String _model  = 'llama-3.3-70b-versatile';

  static const String _systemPrompt = '''
You are GodsConnect Assistant — a helpful, friendly AI assistant for the GodsConnect Hindu temple app.

Your expertise:
- Hindu temples, deities, rituals, festivals, and traditions
- Temple darshan booking, prasadam ordering, event registration
- Homam, pooja, and religious ceremonies
- Temple etiquette (dos and don'ts)
- Prayers, mantras, and their meanings (Gayatri Mantra, Hanuman Chalisa, etc.)
- Festivals like Navratri, Diwali, Shivaratri, Tamil Puthandu, etc.
- Temples in Tamil Nadu and across India

App features you can help with:
- Book Darshan: Normal (₹50/person) or Special (₹100/person)
- Order Prasadam: Temple-specific items, pickup only at temple counter
- Register for Events: Free and paid events at temples
- Make Donations to temples
- Check Crowd Status
- Book Homam services

Always be respectful, warm, and devotional in tone. 
Keep responses concise and helpful.
If asked about something outside temples/religion/the app, politely redirect.
Respond in the same language the user writes in (English or Tamil).
''';

  static Future<String> sendMessage(List<Map<String, String>> history) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model':       _model,
          'max_tokens':  512,
          'temperature': 0.7,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ...history,
          ],
        }),
      ).timeout(const Duration(seconds: 30)); // ✅ Timeout added

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        final err = json.decode(response.body);
        throw Exception(err['error']?['message'] ?? 'API error ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      throw Exception('Failed to get response: $e');
    }
  }
}

// ── Chatbot Page ──────────────────────────────────────────────────────────────
class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final List<_ChatMessage>        _messages   = [];
  final List<Map<String, String>> _history    = [];
  final TextEditingController     _inputCtrl  = TextEditingController();
  final ScrollController          _scrollCtrl = ScrollController();
  bool _isTyping = false;

  static const List<String> _suggestions = [
    '🛕 Nearby temples',
    '📅 Upcoming festivals',
    '🙏 Gayatri Mantra',
    '🎟️ Book darshan',
    '🍽️ Order prasadam',
    '🔥 What is Homam?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: 'Namaste! 🙏 I am your GodsConnect Assistant.\n\nI can help you with:\n• Temple information & darshan booking\n• Prasadam orders & events\n• Prayers, mantras & rituals\n• Festival dates & traditions\n\nHow can I assist you today?',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _isTyping) return;

    _inputCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage(text: msg, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    _history.add({'role': 'user', 'content': msg});

    final typingMsg = _ChatMessage(text: '...', isUser: false, isLoading: true);
    setState(() => _messages.add(typingMsg));
    _scrollToBottom();

    try {
      final reply = await _GroqService.sendMessage(List.from(_history));

      _history.add({'role': 'assistant', 'content': reply});

      setState(() {
        _messages.remove(typingMsg);
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.remove(typingMsg);
        _messages.add(_ChatMessage(
          text: 'Sorry, I couldn\'t connect. Please check your internet and try again. 🙏',
          isUser: false,
        ));
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
        title: const Row(children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 18,
            child: Text('🛕', style: TextStyle(fontSize: 18)),
          ),
          SizedBox(width: 10),
          Text(
            'GodsConnect Assistant',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _history.clear();
                _messages.add(_ChatMessage(
                  text: 'Namaste! 🙏 Chat cleared. How can I help you?',
                  isUser: false,
                ));
              });
            },
          ),
        ],
      ),
      body: Column(children: [
        // ── Messages list ─────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildMessageBubble(msg);
            },
          ),
        ),

        // ── Suggestion chips ──────────────────────────────────────────
        if (_history.isEmpty)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(_suggestions[i],
                    style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.orange.shade50,
                side: BorderSide(color: Colors.orange.shade200),
                onPressed: () => _sendMessage(_suggestions[i]),
              ),
            ),
          ),

        if (_history.isEmpty) const SizedBox(height: 8),

        // ── Input bar ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8, offset: const Offset(0, -3),
            )],
          ),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: TextField(
                    controller: _inputCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: _isTyping ? null : _sendMessage,
                    decoration: const InputDecoration(
                      hintText: 'Ask about temples, prayers...',
                      hintStyle: TextStyle(fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isTyping ? null : () => _sendMessage(_inputCtrl.text),
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _isTyping ? Colors.grey.shade300 : const Color(0xFFFF9933),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isTyping ? Icons.hourglass_empty : Icons.send_rounded,
                    color: Colors.white, size: 22,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    if (msg.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            _TypingDot(delay: 0),
            SizedBox(width: 4),
            _TypingDot(delay: 200),
            SizedBox(width: 4),
            _TypingDot(delay: 400),
          ]),
        ),
      );
    }

    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFFF9933) : Colors.orange.shade50,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: Colors.orange.shade100),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated typing dots ──────────────────────────────────────────────────────
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});
  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>    _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFFF9933),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}