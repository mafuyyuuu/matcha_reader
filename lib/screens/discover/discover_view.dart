import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../search/search_results_view.dart';
import 'widgets/chat_bubble.dart';

class DiscoverView extends ConsumerStatefulWidget {
  const DiscoverView({super.key});

  @override
  ConsumerState<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends ConsumerState<DiscoverView> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<Map<String, String>> _messages = [
    {
      "role": "ai",
      "text": "Hey! I'm Matcha 🍵.\nTell me what you're in the mood for, and I'll find the perfect read for you."
    }
  ];

  @override
  void initState() {
    super.initState();
    // Verify API key on load
    Future.microtask(() {
      final gemini = ref.read(geminiServiceProvider);
      if (!gemini.hasApiKey) {
        setState(() {
          _messages.add({
            "role": "ai",
            "text": "⚠️ API Key missing! Please run the app with: \n--dart-define=GEMINI_API_KEY=your_key_here"
          });
        });
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
    });

    _chatController.clear();
    _scrollToBottom();

    final gemini = ref.read(geminiServiceProvider);
    final prompt = "You are Matcha, an expert manhwa and manga recommendation AI. A user asks: '$text'. Give them 2-3 excellent recommendations. Be concise, friendly, and wrap the manga titles in double asterisks like **TITLE HERE** so they can be interactive.";
    
    final reply = await gemini.sendMessage(prompt);

    setState(() {
      _messages.add({"role": "ai", "text": reply});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<String> _extractTitles(String text) {
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    final matches = exp.allMatches(text);
    return matches.map((m) => m.group(1)!.trim()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
            child: Text('AI Discover Engine', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.darkForest, letterSpacing: -0.5)),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildQuickPrompt("Dark Fantasy & Leveling"),
                _buildQuickPrompt("Reincarnated as a Villain"),
                _buildQuickPrompt("Cozy Slice of Life"),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                final text = msg["text"]!;

                List<String> suggestedTitles = isUser ? [] : _extractTitles(text);

                return Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    ChatBubble(text: text, isUser: isUser),

                    if (suggestedTitles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16, left: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: suggestedTitles.map((title) {
                            return ActionChip(
                              backgroundColor: AppColors.softMintBg,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              label: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 120),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search, size: 14, color: AppColors.matchaGreen),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        title,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.sageText),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchResultsView(query: title),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.matchaGreen),
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.softMintBg, width: 1.5),
                    ),
                    child: TextField(
                      controller: _chatController,
                      decoration: const InputDecoration(
                        hintText: 'Describe your next read...',
                        hintStyle: TextStyle(color: AppColors.mutedSage, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _sendMessage(_chatController.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: AppColors.matchaGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompt(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.softMintBg),
        ),
        child: Text(text, style: const TextStyle(color: AppColors.sageText, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
