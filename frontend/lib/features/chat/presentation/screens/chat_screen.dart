import 'dart:async';
import 'package:flutter/material.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: "Hi! I'm CLAiR, how may I assist you today?",
      isUser: false,
    ),
    const _ChatMessage(
      text: "I need assistance for a specific land dispute with my family.",
      isUser: true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(const _ChatMessage(
          text:
              "I understand your concern. Land dispute cases can be complex. Could you provide more details about the specific nature of the dispute and the parties involved?",
          isUser: false,
        ));
      });
      _scrollToBottom();
    });
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ClairAppBar(chatTitle: 'Land Dispute Assistance'),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isTyping) {
                return _buildTypingIndicator();
              }
              final msg = _messages[index];
              return msg.isUser
                  ? _buildUserMessage(msg.text)
                  : _buildAiMessage(msg.text);
            },
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildAiMessage(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.tan, width: 1),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/CLAiR-icon.png',
              fit: BoxFit.contain,
              color: AppColors.darkBrown,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkBrown.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkBrown,
                      fontFamily: 'Satoshi',
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildActionIcon(Icons.copy_rounded),
                    _buildActionIcon(Icons.thumb_up_outlined),
                    _buildActionIcon(Icons.thumb_down_outlined),
                    _buildActionIcon(Icons.refresh_rounded),
                    _buildActionIcon(Icons.more_horiz_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.darkBrown,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontFamily: 'Satoshi',
                height: 1.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionIcon(Icons.copy_rounded),
              _buildActionIcon(Icons.edit_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.tan, width: 1),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/CLAiR-icon.png',
              fit: BoxFit.contain,
              color: AppColors.darkBrown,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '...CLAiR is typing',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.darkBrown.withOpacity(0.45),
              fontFamily: 'Satoshi',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Icon(icon, size: 15, color: AppColors.tan),
    );
  }

  Widget _buildInputBar() {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.tan,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBrown,
                        fontFamily: 'Satoshi',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ask anything',
                        hintStyle: TextStyle(
                          color: AppColors.tan,
                          fontFamily: 'Satoshi',
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.darkBrown,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Icon(
              Icons.mic_none_rounded,
              color: AppColors.tan,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}
