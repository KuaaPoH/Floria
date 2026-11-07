import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart' hide ChatSession;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/widgets/custom_image.dart';
import '../../garden/providers/garden_provider.dart';
import '../../shop/providers/shop_provider.dart';
import '../../shop/screens/product_detail_screen.dart';
import '../models/chat_session.dart';
import '../providers/chat_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';

class CareScheduleProposal {
  final int waterDays;
  final int fertilizeDays;
  final int cleanDays;
  bool isApplied;

  CareScheduleProposal({
    required this.waterDays,
    required this.fertilizeDays,
    required this.cleanDays,
    this.isApplied = false,
  });
}

class ChatMessageItem {
  final bool isUser;
  String text;
  final Uint8List? imageBytes;
  final DateTime timestamp;
  List<String> recommendedProductIds;
  CareScheduleProposal? careProposal;
  bool isStreaming;

  ChatMessageItem({
    required this.isUser,
    required this.text,
    this.imageBytes,
    DateTime? timestamp,
    this.recommendedProductIds = const [],
    this.careProposal,
    this.isStreaming = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiAssistantScreen extends StatefulWidget {
  final String? plantId;
  final String? plantNameVi;
  final String? scientificName;
  final String? diseaseContext;

  const AiAssistantScreen({
    super.key,
    this.plantId,
    this.plantNameVi,
    this.scientificName,
    this.diseaseContext,
  });

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<ChatMessageItem> _messages = [];
  final List<Content> _chatHistory = [];

  bool _isLoading = false;
  bool _hasApiKey = false;
  bool _enableDeepThinking = false;
  Uint8List? _attachedImageBytes;

  String? _currentSessionId;
  String? _currentSessionTitle;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _loadThinkingMode();
    _initWelcomeMessage();
  }

  Future<void> _loadThinkingMode() async {
    final isDeep = await GeminiService.getDeepThinkingMode();
    if (mounted) {
      setState(() {
        _enableDeepThinking = isDeep;
      });
    }
  }

  Future<void> _checkApiKey() async {
    final hasKey = await GeminiService.hasApiKey();
    if (mounted) {
      setState(() {
        _hasApiKey = hasKey;
      });
    }
  }

  void _initWelcomeMessage() {
    String welcome = "Xin chào! Tôi là Trợ lý Floria 🌿\n\nTôi có thể giúp bạn chẩn đoán sâu bệnh, tư vấn lịch tưới nước, ánh sáng và phân bón chuẩn khoa học. Bạn có thể hỏi tôi bất kỳ thắc mắc nào hoặc đính kèm ảnh cây để tôi hỗ trợ nhé!";
    if (widget.plantNameVi != null && widget.plantNameVi!.isNotEmpty) {
      final sci = widget.scientificName != null && widget.scientificName!.isNotEmpty ? ' (${widget.scientificName})' : '';
      welcome = "Chào bạn! Tôi là Trợ lý Floria 🌿\n\nTôi đang theo dõi chuyên sâu cho cây **${widget.plantNameVi}**$sci của bạn.\n${widget.diseaseContext != null ? '📌 *Tình trạng hiện tại: ${widget.diseaseContext}*\n\n' : '\n'}Tôi đã nạp đầy đủ thông tin sinh học của loài cây này. Bạn cần tôi hướng dẫn cách tưới nước, ánh sáng, nhiệt độ hay chẩn đoán triệu chứng bất thường nào trên cây?";
    }
    _messages.add(ChatMessageItem(isUser: false, text: welcome));
  }

  Future<void> _startNewChat() async {
    // Nếu phiên hiện tại có tin nhắn người dùng nhưng chưa được lưu, tự động lưu ngay trước khi tạo phiên mới
    final userMsgs = _messages.where((m) => m.isUser).toList();
    if (_currentSessionId == null && userMsgs.isNotEmpty) {
      try {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final sessionMsgs = _messages.map((m) => ChatSessionMessage(
          isUser: m.isUser,
          text: m.text,
          timestamp: m.timestamp,
          recommendedProductIds: m.recommendedProductIds,
        )).toList();

        await chatProvider.createSession(
          firstUserPrompt: userMsgs.first.text,
          messages: sessionMsgs,
          customTitle: _currentSessionTitle,
        );
      } catch (e) {
        debugPrint("Lỗi tự động lưu phiên cũ trước khi tạo mới: $e");
      }
    }

    setState(() {
      _currentSessionId = null;
      _currentSessionTitle = null;
      _messages.clear();
      _chatHistory.clear();
      _attachedImageBytes = null;
      _initWelcomeMessage();
    });
    _scrollToBottom();
  }

  void _showRenameDialog(BuildContext context, {required String sessionId, required String currentTitle}) {
    final c = context.colors;
    final textController = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        surfaceTintColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: c.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              context.tr("Đổi tên cuộc trò chuyện", "Rename Chat"),
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr("Nhập tên gợi nhớ cho cuộc trò chuyện này:", "Enter a memorable name for this chat:"),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
              cursorColor: c.primary,
              decoration: InputDecoration(
                hintText: context.tr("Ví dụ: Hỏi chăm sóc Cây Lưỡi Hổ...", "E.g. Snake Plant care questions..."),
                hintStyle: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: c.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.primary, width: 1.8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr("Hủy", "Cancel"),
              style: GoogleFonts.inter(
                color: c.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                final provider = Provider.of<ChatProvider>(context, listen: false);
                await provider.renameSession(sessionId: sessionId, newTitle: newName);
                if (_currentSessionId == sessionId) {
                  setState(() {
                    _currentSessionTitle = newName;
                  });
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(context.tr("Lưu tên", "Save")),
          ),
        ],
      ),
    );
  }

  void _loadSession(ChatSession session) {
    setState(() {
      _currentSessionId = session.id;
      _currentSessionTitle = session.title;
      _messages.clear();
      _chatHistory.clear();
      _attachedImageBytes = null;

      for (final m in session.messages) {
        _messages.add(ChatMessageItem(
          isUser: m.isUser,
          text: m.text,
          timestamp: m.timestamp,
          recommendedProductIds: m.recommendedProductIds,
        ));

        if (m.isUser) {
          _chatHistory.add(Content.text(m.text));
        } else {
          _chatHistory.add(Content.model([TextPart(m.text)]));
        }
      }
    });
    _scrollToBottom();
  }

  String _formatSessionTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return context.tr("Vừa xong", "Just now");
    if (diff.inMinutes < 60) return "${diff.inMinutes} ${context.tr('phút trước', 'mins ago')}";
    if (diff.inHours < 24) return "${diff.inHours} ${context.tr('giờ trước', 'hours ago')}";
    if (diff.inDays < 7) return "${diff.inDays} ${context.tr('ngày trước', 'days ago')}";
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  void _confirmDeleteSession(BuildContext context, ChatSession session) {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 8),
            Text(
              context.tr("Xóa cuộc trò chuyện", "Delete Chat"),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          "${context.tr('Bạn có chắc muốn xóa', 'Are you sure you want to delete')} '${session.title}'? ${context.tr('Thao tác này sẽ xóa toàn bộ nội dung trong cuộc trò chuyện này.', 'This will delete all messages in this conversation.')}",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: c.textSecondary,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr("Hủy", "Cancel"),
              style: GoogleFonts.inter(
                color: c.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<ChatProvider>(context, listen: false);
              await provider.deleteSession(session.id);
              if (_currentSessionId == session.id) {
                _startNewChat();
              }
            },
            child: Text(
              context.tr("Xóa", "Delete"),
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer() {
    final c = context.colors;
    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.primary.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.psychology, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr("Lịch sử trò chuyện", "Chat History"),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          context.tr("Danh sách các phiên tư vấn AI", "List of AI consultations"),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nút Tạo cuộc trò chuyện mới
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _startNewChat();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                    boxShadow: [
                      BoxShadow(
                        color: c.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: c.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        context.tr("Cuộc trò chuyện mới", "New Chat"),
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),
            Divider(height: 1, color: c.border),

            // Danh sách các cuộc trò chuyện
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading) {
                    return Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2.5));
                  }
                  final sessions = chatProvider.sessions;
                  if (sessions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 44, color: c.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              context.tr("Chưa có cuộc trò chuyện nào", "No conversations yet"),
                              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr("Các câu hỏi của bạn với Bác sĩ Cây trồng sẽ được tự động lưu tại đây.", "Your questions with Plant Doctor will be saved here."),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 12, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isSelected = session.id == _currentSessionId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? c.surfaceTint : c.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? c.primary : c.border,
                            width: isSelected ? 1.4 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.shadow,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: Icon(
                            isSelected ? Icons.chat_rounded : Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: isSelected ? c.primary : c.textMuted,
                          ),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? c.primary : c.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            "${_formatSessionTime(session.updatedAt)} • ${session.messages.length} ${context.tr('tin nhắn', 'messages')}",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isSelected ? c.primary : c.textMuted,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 17, color: c.textMuted),
                                tooltip: context.tr("Đổi tên", "Rename"),
                                splashRadius: 18,
                                onPressed: () => _showRenameDialog(
                                  context,
                                  sessionId: session.id,
                                  currentTitle: session.title,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, size: 17, color: c.textMuted),
                                tooltip: context.tr("Xóa", "Delete"),
                                splashRadius: 18,
                                onPressed: () => _confirmDeleteSession(context, session),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _loadSession(session);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _attachedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi chọn ảnh: $e")),
        );
      }
    }
  }

  Future<void> _handleSendMessage({String? customText}) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty && _attachedImageBytes == null) return;

    if (!_hasApiKey) {
      GeminiService.showApiKeyDialog(context, onSaved: () {
        _checkApiKey();
        if (text.isNotEmpty || _attachedImageBytes != null) {
          _handleSendMessage(customText: text);
        }
      });
      return;
    }

    final userImage = _attachedImageBytes;
    final userPrompt = text.isEmpty && userImage != null ? "Khám bệnh cho cây qua hình ảnh này giúp tôi" : text;
    final aiPlaceholder = ChatMessageItem(
      isUser: false,
      text: "",
      isStreaming: true,
    );

    setState(() {
      _messages.add(ChatMessageItem(
        isUser: true,
        text: userPrompt,
        imageBytes: userImage,
      ));
      _messages.add(aiPlaceholder);
      _isLoading = false;
      _messageController.clear();
      _attachedImageBytes = null;
    });
    _scrollToBottom();

    try {
      String plantCtx = "";
      if (widget.plantNameVi != null && widget.plantNameVi!.isNotEmpty) {
        plantCtx = "Cây ${widget.plantNameVi} (${widget.scientificName ?? ''})";
        if (widget.diseaseContext != null) {
          plantCtx += ", tình trạng: ${widget.diseaseContext}";
        }
      }

      String accumulated = "";
      final productRegex = RegExp(r'\[RECOMMEND_PRODUCT:\s*([a-zA-Z0-9_\-]+)\]');
      final careRegex = RegExp(r'\[CARE_SCHEDULE:\s*water=(\d+),\s*fertilize=(\d+),\s*clean=(\d+)\]');

      String sanitizeDisplay(String raw) {
        var s = raw
            .replaceAll(productRegex, '')
            .replaceAll(careRegex, '')
            .trimRight();
        // Gọt bỏ tiêu đề đề xuất lịch chăm sóc treo cụt ở cuối văn bản nếu có
        s = s.replaceAll(RegExp(r'\n+\s*\*\*Lịch chăm sóc đề xuất[^\*]*\*\*[:\s]*$', caseSensitive: false), '');
        s = s.replaceAll(RegExp(r'\n+\s*Lịch chăm sóc đề xuất[^:\n]*[:\s]*$', caseSensitive: false), '');
        return s.trim();
      }

      await for (final chunk in GeminiService.chatWithDoctorStream(
        prompt: userPrompt,
        history: _chatHistory,
        imageBytes: userImage,
        currentPlantContext: plantCtx,
        enableDeepThinking: _enableDeepThinking,
      )) {
        accumulated += chunk;
        if (mounted) {
          setState(() {
            // Ẩn tạm tag sản phẩm và tag lịch chăm sóc trong lúc stream để giao diện không bị giật
            aiPlaceholder.text = sanitizeDisplay(accumulated);
          });
          _scrollToBottom();
        }
      }

      // Khi stream xong: trích xuất các sản phẩm được kê đơn
      final matches = productRegex.allMatches(accumulated);
      final List<String> productIds = [];
      for (final m in matches) {
        if (m.group(1) != null) {
          final pid = m.group(1)!.trim();
          if (!productIds.contains(pid)) productIds.add(pid);
        }
      }

      // Trích xuất đề xuất lịch chăm sóc từ AI
      CareScheduleProposal? proposedCare;
      final careMatch = careRegex.firstMatch(accumulated);
      if (careMatch != null) {
        final w = int.tryParse(careMatch.group(1) ?? '3') ?? 3;
        final f = int.tryParse(careMatch.group(2) ?? '20') ?? 20;
        final c = int.tryParse(careMatch.group(3) ?? '3') ?? 3;
        proposedCare = CareScheduleProposal(waterDays: w, fertilizeDays: f, cleanDays: c);
      }

      final cleanFinal = sanitizeDisplay(accumulated);

      if (mounted) {
        setState(() {
          aiPlaceholder.text = cleanFinal;
          aiPlaceholder.recommendedProductIds = productIds;
          aiPlaceholder.careProposal = proposedCare;
          aiPlaceholder.isStreaming = false;
        });
        _scrollToBottom();
      }

      // Cập nhật lịch sử hội thoại cho Gemini
      if (userImage != null) {
        _chatHistory.add(Content.multi([
          TextPart(userPrompt),
          DataPart('image/jpeg', userImage),
        ]));
      } else {
        _chatHistory.add(Content.text(userPrompt));
      }
      _chatHistory.add(Content.model([TextPart(cleanFinal)]));

      // Tự động lưu/cập nhật phiên trò chuyện lên Cloud Firestore
      try {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final sessionMsgs = _messages.map((m) => ChatSessionMessage(
          isUser: m.isUser,
          text: m.text,
          timestamp: m.timestamp,
          recommendedProductIds: m.recommendedProductIds,
        )).toList();

        if (_currentSessionId == null) {
          final fallbackTitle = userPrompt.length > 35 ? '${userPrompt.substring(0, 35)}...' : userPrompt;
          final newId = await chatProvider.createSession(
            firstUserPrompt: userPrompt,
            messages: sessionMsgs,
            customTitle: fallbackTitle,
          );
          if (newId != null && mounted) {
            setState(() {
              _currentSessionId = newId;
              _currentSessionTitle = fallbackTitle;
            });

            // Tự động yêu cầu AI tóm tắt đặt tên cuộc trò chuyện thông minh như ChatGPT
            GeminiService.generateConversationTitle(
              userPrompt: userPrompt,
              aiResponse: cleanFinal,
            ).then((smartTitle) {
              if (smartTitle != null && smartTitle.isNotEmpty && mounted) {
                chatProvider.renameSession(sessionId: newId, newTitle: smartTitle);
                if (_currentSessionId == newId) {
                  setState(() {
                    _currentSessionTitle = smartTitle;
                  });
                }
              }
            });
          }
        } else {
          await chatProvider.updateSessionMessages(
            sessionId: _currentSessionId!,
            messages: sessionMsgs,
          );
        }
      } catch (err) {
        debugPrint("Lỗi tự động lưu ChatSession: $err");
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          aiPlaceholder.text = "⚠️ Đã có sự cố khi kết nối với Trợ lý Floria: ${e.toString().replaceAll('Exception: ', '')}.\n\nVui lòng kiểm tra lại kết nối mạng.";
          aiPlaceholder.isStreaming = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final String activePlant = widget.plantNameVi ?? "";

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildHistoryDrawer(),
      backgroundColor: c.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(bottom: BorderSide(color: c.border)),
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: c.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.psychology, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _currentSessionId != null
                          ? () => _showRenameDialog(
                                context,
                                sessionId: _currentSessionId!,
                                currentTitle: _currentSessionTitle ?? context.tr("Cuộc trò chuyện mới", "New Chat"),
                              )
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  context.tr("Trợ lý Floria", "Floria Assistant"),
                                  style: GoogleFonts.inter(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: c.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00C853),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentSessionTitle != null
                                  ? "$_currentSessionTitle • ${context.tr('Đang trực tuyến', 'Online')}"
                                  : context.tr("Đang trực tuyến", "Online"),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: c.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Nút tạo cuộc trò chuyện mới
                  IconButton(
                    icon: Icon(Icons.add_comment_outlined, color: c.primary, size: 21),
                    tooltip: context.tr("Cuộc trò chuyện mới", "New Chat"),
                    onPressed: _startNewChat,
                  ),
                  // Nút mở lịch sử trò chuyện
                  IconButton(
                    icon: Icon(Icons.history_rounded, color: c.primary, size: 22),
                    tooltip: context.tr("Lịch sử trò chuyện", "Chat History"),
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Banner thông tin cây đang khám nếu có
          if (activePlant.isNotEmpty) _buildContextBar(activePlant),

          // Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Thanh nhập tin nhắn và đính kèm
          _buildInputDock(),
        ],
      ),
    );
  }

  Widget _buildContextBar(String plantName) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: c.surfaceTint,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_florist, size: 16, color: c.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${context.tr('Đang trò chuyện về:', 'Chatting about:')} $plantName ${widget.diseaseContext != null ? '(${widget.diseaseContext})' : ''}",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem msg) {
    final c = context.colors;
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 48),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (msg.imageBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          msg.imageBytes!,
                          width: 200,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (msg.text.isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (msg.text.isNotEmpty)
                      Text(
                        msg.text,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.45,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                color: c.surfaceTint,
                shape: BoxShape.circle,
                border: Border.all(color: c.primary.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.eco, color: c.primary, size: 18),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  border: Border.all(color: c.border),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.isStreaming && msg.text.isEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.tr("Đang suy nghĩ...", "Thinking..."),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: c.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      MarkdownBody(
                        data: msg.isStreaming ? "${msg.text} ▍" : msg.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.6,
                            color: c.textPrimary,
                          ),
                          strong: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.primaryText,
                          ),
                          em: GoogleFonts.inter(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: c.textSecondary,
                          ),
                          h1: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: c.primaryText,
                          ),
                          h2: GoogleFonts.inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: c.primaryText,
                          ),
                          h3: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: c.primary,
                          ),
                          listBullet: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: c.primary,
                          ),
                          blockquote: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                            color: c.primary,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: c.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(color: c.primary, width: 3.5),
                            ),
                          ),
                          code: GoogleFonts.robotoMono(
                            fontSize: 12.5,
                            color: c.primary,
                            backgroundColor: c.surfaceTint,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: c.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: c.border),
                          ),
                        ),
                      ),
                      if (!msg.isStreaming && msg.text.isNotEmpty)
                        _buildAiMessageActions(msg),
                    ],
                    if (msg.recommendedProductIds.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.surfaceTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.medical_services_rounded, color: c.primary, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              context.tr("TRỢ LÝ FLORIA KÊ ĐƠN VẬT TƯ ĐIỀU TRỊ", "FLORIA ASSISTANT TREATMENT PRESCRIPTION"),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: c.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...msg.recommendedProductIds.map((pid) => _buildProductRecommendationCard(pid)),
                    ],
                    if (msg.careProposal != null) ...[
                      const SizedBox(height: 12),
                      _buildCareScheduleProposalCard(msg.careProposal!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 32),
          ],
        ),
      );
    }
  }

  void _showAppToast({
    required String title,
    String? subtitle,
    IconData icon = Icons.check_circle_rounded,
    Color iconColor = const Color(0xFF4ADE80),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E3A24),
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB4F4C2),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiMessageActions(ChatMessageItem msg) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: msg.text));
              _showAppToast(
                title: context.tr("Đã sao chép vào bộ nhớ tạm", "Copied to clipboard"),
                subtitle: context.tr("Nội dung phản hồi đã sẵn sàng để dán.", "Response content ready to paste."),
                icon: Icons.copy_rounded,
                iconColor: const Color(0xFF4ADE80),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 13, color: c.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    context.tr("Sao chép", "Copy"),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRecommendationCard(String productId) {
    final c = context.colors;
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final product = shopProvider.getProductById(productId);
    if (product == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomImage(
              imageUrl: product.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.formattedPrice,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: c.border),
                        ),
                        child: Text(
                          context.tr("Chi tiết", "Details"),
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        shopProvider.addToCart(product);
                        _showAppToast(
                          title: context.tr("Đã thêm vào giỏ hàng", "Added to cart"),
                          subtitle: product.name,
                          icon: Icons.shopping_bag_outlined,
                          iconColor: const Color(0xFF4ADE80),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              context.tr("Mua ngay", "Buy now"),
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
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
        ],
      ),
    );
  }

  Widget _buildCareScheduleProposalCard(CareScheduleProposal proposal) {
    final c = context.colors;
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);

    // Tìm cây trong vườn khớp với ngữ cảnh hiện tại
    final matchingPlant = widget.plantId != null
        ? gardenProvider.plants.firstWhere(
            (p) => p.id == widget.plantId,
            orElse: () => gardenProvider.plants.firstWhere(
              (p) => p.nameVi.toLowerCase() == (widget.plantNameVi ?? '').toLowerCase(),
              orElse: () => gardenProvider.plants.isNotEmpty ? gardenProvider.plants.first : throw Exception("No plants"),
            ),
          )
        : (gardenProvider.plants.any((p) => p.nameVi.toLowerCase() == (widget.plantNameVi ?? '').toLowerCase())
            ? gardenProvider.plants.firstWhere((p) => p.nameVi.toLowerCase() == (widget.plantNameVi ?? '').toLowerCase())
            : (gardenProvider.plants.isNotEmpty ? gardenProvider.plants.first : null));

    final targetName = matchingPlant?.nickname ?? widget.plantNameVi ?? context.tr("Cây của bạn", "Your plant");

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome_rounded, color: c.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr("ĐỀ XUẤT LỊCH CHĂM SÓC TỪ TRỢ LÝ FLORIA", "CARE SCHEDULE PROPOSAL FROM FLORIA"),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: c.primary,
                      ),
                    ),
                    Text(
                      "${context.tr("Áp dụng cho:", "Apply to:")} $targetName",
                      style: GoogleFonts.inter(fontSize: 11.5, color: c.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 10),

          // 3 thông số đề xuất
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCareParamBadge(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF0284C7),
                title: context.tr("Tưới nước", "Watering"),
                value: "${proposal.waterDays} ${context.tr("ngày/lần", "days/time")}",
              ),
              _buildCareParamBadge(
                icon: Icons.science_rounded,
                iconColor: const Color(0xFFD97706),
                title: context.tr("Bón phân", "Fertilizing"),
                value: "${proposal.fertilizeDays} ${context.tr("ngày/lần", "days/time")}",
              ),
              _buildCareParamBadge(
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF16A34A),
                title: context.tr("Lau lá/Soi sâu", "Pest/Clean"),
                value: "${proposal.cleanDays} ${context.tr("ngày/lần", "days/time")}",
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nút bấm áp dụng vào cây
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: proposal.isApplied || matchingPlant == null
                  ? null
                  : () async {
                      final success = await gardenProvider.updatePlantInfo(
                        matchingPlant.id,
                        nickname: matchingPlant.nickname,
                        zone: matchingPlant.zone,
                        waterFrequencyDays: proposal.waterDays,
                        fertilizeFrequencyDays: proposal.fertilizeDays,
                        checkPestFrequencyDays: proposal.cleanDays,
                        reminderTime: matchingPlant.reminderTime,
                        healthStatus: matchingPlant.healthStatus,
                        notes: matchingPlant.notes,
                      );

                      if (mounted && success) {
                        setState(() {
                          proposal.isApplied = true;
                        });
                        _showAppToast(
                          title: "${context.tr("Đã cập nhật lịch cho", "Updated schedule for")} '$targetName'!",
                          subtitle: context.tr(
                            "Lịch chăm sóc thực tế trong vườn đã đồng bộ theo Trợ lý Floria.",
                            "Real garden care schedule synced with Floria Assistant.",
                          ),
                          icon: Icons.check_circle_rounded,
                          iconColor: const Color(0xFF4ADE80),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                disabledBackgroundColor: c.surfaceMuted,
                foregroundColor: Colors.white,
                disabledForegroundColor: c.textMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: proposal.isApplied ? 0 : 2,
              ),
              icon: Icon(
                proposal.isApplied ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                size: 16,
                color: proposal.isApplied ? const Color(0xFF16A34A) : Colors.white,
              ),
              label: Text(
                proposal.isApplied
                    ? context.tr("Đã áp dụng vào cây trồng ✓", "Applied to plant ✓")
                    : context.tr("Áp dụng lịch này vào cây", "Apply schedule to plant"),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: proposal.isApplied ? const Color(0xFF16A34A) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareParamBadge({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    final c = context.colors;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco, color: c.primary, size: 18),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr("Đang suy nghĩ...", "Thinking..."),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: c.primary,
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

  Widget _buildInputDock() {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ảnh đính kèm xem trước nếu có
            if (_attachedImageBytes != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _attachedImageBytes!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr("Đã đính kèm ảnh cây để Trợ lý Floria chẩn đoán", "Attached plant photo for Floria diagnosis"),
                        style: GoogleFonts.inter(fontSize: 12, color: c.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: c.textMuted),
                      onPressed: () => setState(() => _attachedImageBytes = null),
                    ),
                  ],
                ),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.camera_alt_outlined, color: c.primary),
                  tooltip: context.tr("Chụp ảnh cây", "Take plant photo"),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                IconButton(
                  icon: Icon(Icons.photo_outlined, color: c.primary),
                  tooltip: context.tr("Chọn ảnh từ thư viện", "Pick from gallery"),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: c.border),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      style: GoogleFonts.inter(fontSize: 14, color: c.textPrimary),
                      decoration: InputDecoration(
                        hintText: context.tr("Hỏi Trợ lý Floria về sâu bệnh, tưới nước...", "Ask Floria about pests, watering..."),
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _isLoading ? null : () => _handleSendMessage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
