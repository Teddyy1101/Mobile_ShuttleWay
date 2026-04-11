import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/chatbot_controller.dart';
import '../widgets/chat_bubble_widget.dart';

/// Màn hình Chatbot AI — Tư vấn tuyến đường, giá vé, trạm dừng.
/// Lịch sử hội thoại được lưu session-based, reset khi thoát màn hình.
class ChatbotScreen extends StatefulWidget {
  final ChatbotController chatbotController;

  const ChatbotScreen({super.key, required this.chatbotController});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    // Reset phiên hội thoại khi thoát màn hình
    widget.chatbotController.resetSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(colorScheme, isDark),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: widget.chatbotController,
                builder: (context, _) {
                  final messages = widget.chatbotController.messages;

                  if (messages.isEmpty) {
                    return _buildWelcomeView(colorScheme, isDark);
                  }

                  return _buildMessageList(messages, colorScheme, isDark);
                },
              ),
            ),
            _buildInputBar(colorScheme, isDark),
          ],
        ),
      ),
    );
  }

  /// AppBar với title và icon.
  PreferredSizeWidget _buildAppBar(
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppConstants.paddingSM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tư vấn AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Hỏi đáp thông minh',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
    );
  }

  /// Giao diện chào mừng khi chưa có tin nhắn nào.
  Widget _buildWelcomeView(ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // AI icon lớn
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.15),
                  colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLG),
          Text(
            'Xin chào! 👋',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSM),
          Text(
            'Tôi là trợ lý AI của ShuttleWay.\n'
            'Hãy hỏi tôi về tuyến đường, giá vé, trạm dừng!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppConstants.paddingXL),
          // Gợi ý câu hỏi
          _buildSuggestionChip(
            colorScheme,
            isDark,
            'Liệt kê các tuyến đường',
            Icons.route_rounded,
          ),
          const SizedBox(height: AppConstants.paddingSM),
          _buildSuggestionChip(
            colorScheme,
            isDark,
            'Giá vé tháng bao nhiêu?',
            Icons.confirmation_number_rounded,
          ),
          const SizedBox(height: AppConstants.paddingSM),
          _buildSuggestionChip(
            colorScheme,
            isDark,
            'Tuyến nào đi qua trạm trường?',
            Icons.location_on_rounded,
          ),
          const SizedBox(height: AppConstants.paddingSM),
          _buildSuggestionChip(
            colorScheme,
            isDark,
            'Vé của tôi còn hạn không?',
            Icons.timer_rounded,
          ),
        ],
      ),
    );
  }

  /// Chip gợi ý câu hỏi — nhấn để gửi luôn.
  Widget _buildSuggestionChip(
    ColorScheme colorScheme,
    bool isDark,
    String text,
    IconData icon,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendMessage(text),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMD,
            vertical: AppConstants.paddingSM + 4,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: AppConstants.paddingSM),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Danh sách tin nhắn.
  Widget _buildMessageList(
    List<ChatMessage> messages,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSM),
      itemCount: messages.length + (widget.chatbotController.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator
        if (index == messages.length) {
          return _buildTypingIndicator(colorScheme, isDark);
        }

        final msg = messages[index];
        return ChatBubbleWidget(
          message: msg.content,
          isUser: msg.isUser,
          time: DateFormat('HH:mm').format(msg.timestamp),
        );
      },
    );
  }

  /// Typing indicator khi AI đang trả lời.
  Widget _buildTypingIndicator(ColorScheme colorScheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar AI
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppConstants.paddingSM),
          // Dots animation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF0F2F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(colorScheme, 0),
                const SizedBox(width: 4),
                _buildDot(colorScheme, 1),
                const SizedBox(width: 4),
                _buildDot(colorScheme, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dot animation cho typing indicator.
  Widget _buildDot(ColorScheme colorScheme, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  /// Thanh nhập tin nhắn ở bottom.
  Widget _buildInputBar(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.paddingMD,
        right: AppConstants.paddingSM,
        top: AppConstants.paddingSM,
        bottom: MediaQuery.of(context).padding.bottom + AppConstants.paddingSM,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _onSendPressed(),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingSM),
          ListenableBuilder(
            listenable: widget.chatbotController,
            builder: (context, _) {
              final isLoading = widget.chatbotController.isLoading;
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLoading
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : colorScheme.primary,
                ),
                child: IconButton(
                  onPressed: isLoading ? null : _onSendPressed,
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                  padding: EdgeInsets.zero,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Xử lý khi nhấn nút gửi.
  void _onSendPressed() {
    final text = _inputController.text.trim();
    if (text.isEmpty || widget.chatbotController.isLoading) return;

    _sendMessage(text);
  }

  /// Gửi tin nhắn và scroll xuống cuối.
  void _sendMessage(String text) {
    _inputController.clear();
    widget.chatbotController.sendMessage(text);

    // Scroll xuống cuối sau khi thêm tin nhắn
    _scrollToBottom();
  }

  /// Scroll danh sách tin nhắn xuống cuối.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
