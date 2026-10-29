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
    final textController = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFF2E6F40), size: 24),
            const SizedBox(width: 8),
            Text(
              "Đổi tên cuộc trò chuyện",
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF151E16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Nhập tên gợi nhớ cho cuộc trò chuyện này:",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF151E16),
              ),
              cursorColor: const Color(0xFF2E6F40),
              decoration: InputDecoration(
                hintText: "Ví dụ: Hỏi chăm sóc Cây Lưỡi Hổ...",
                hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF3F6F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDE3DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E6F40), width: 1.8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Hủy",
              style: GoogleFonts.inter(
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E6F40),
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
            child: const Text("Lưu tên"),
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
    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    if (diff.inDays < 7) return "${diff.inDays} ngày trước";
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  void _confirmDeleteSession(BuildContext context, ChatSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 8),
            Text(
              "Xóa cuộc trò chuyện",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: Text(
          "Bạn có chắc muốn xóa '${session.title}'? Thao tác này sẽ xóa toàn bộ nội dung trong cuộc trò chuyện này.",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Hủy",
              style: GoogleFonts.inter(
                color: const Color(0xFF4B5563),
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
              "Xóa",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF7F9F6),
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
                      color: const Color(0xFF364534),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF364534).withValues(alpha: 0.2),
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
                          "Lịch sử trò chuyện",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF151E16),
                          ),
                        ),
                        Text(
                          "Danh sách các phiên tư vấn AI",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E6F40).withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2E6F40), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Cuộc trò chuyện mới",
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E6F40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),
            const Divider(height: 1, color: Color(0xFFE4E8E2)),

            // Danh sách các cuộc trò chuyện
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF364534), strokeWidth: 2.5));
                  }
                  final sessions = chatProvider.sessions;
                  if (sessions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 44, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              "Chưa có cuộc trò chuyện nào",
                              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Các câu hỏi của bạn với Bác sĩ Cây trồng sẽ được tự động lưu tại đây.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
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
                          color: isSelected ? const Color(0xFFE7F3E8) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF66BB6A) : const Color(0xFFE5E9E4),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
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
                            color: isSelected ? const Color(0xFF2E6F40) : const Color(0xFF6B7280),
                          ),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF1B3B22) : const Color(0xFF1B1C1A),
                            ),
                          ),
                          subtitle: Text(
                            "${_formatSessionTime(session.updatedAt)} • ${session.messages.length} tin nhắn",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isSelected ? const Color(0xFF2E6F40) : const Color(0xFF6B7280),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF6B7280)),
                                tooltip: "Đổi tên",
                                splashRadius: 18,
                                onPressed: () => _showRenameDialog(
                                  context,
                                  sessionId: session.id,
                                  currentTitle: session.title,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFF9CA3AF)),
                                tooltip: "Xóa",
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
    final String activePlant = widget.plantNameVi ?? "";

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildHistoryDrawer(),
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF151E16), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF364534),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF364534).withValues(alpha: 0.25),
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
                                currentTitle: _currentSessionTitle ?? "Cuộc trò chuyện mới",
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
                                  "Trợ lý Floria",
                                  style: GoogleFonts.inter(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF151E16),
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
                                  ? "$_currentSessionTitle • Đang trực tuyến"
                                  : "Đang trực tuyến",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF364534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Nút tạo cuộc trò chuyện mới
                  IconButton(
                    icon: const Icon(Icons.add_comment_outlined, color: Color(0xFF364534), size: 21),
                    tooltip: "Cuộc trò chuyện mới",
                    onPressed: _startNewChat,
                  ),
                  // Nút mở lịch sử trò chuyện
                  IconButton(
                    icon: const Icon(Icons.history_rounded, color: Color(0xFF364534), size: 22),
                    tooltip: "Lịch sử trò chuyện",
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF364534).withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: const Color(0xFF364534).withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_florist, size: 16, color: Color(0xFF364534)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Đang trò chuyện về: $plantName ${widget.diseaseContext != null ? '(${widget.diseaseContext})' : ''}",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF364534),
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
                  color: const Color(0xFF364534),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF364534).withValues(alpha: 0.15),
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
                color: const Color(0xFF364534).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF364534).withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.eco, color: Color(0xFF364534), size: 18),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  border: Border.all(color: const Color(0xFFE4E2DF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
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
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2E6F40),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Đang suy nghĩ...",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF364534),
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
                            color: const Color(0xFF1E241E),
                          ),
                          strong: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B3B22),
                          ),
                          em: GoogleFonts.inter(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF374151),
                          ),
                          h1: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B3B22),
                          ),
                          h2: GoogleFonts.inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B3B22),
                          ),
                          h3: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E6F40),
                          ),
                          listBullet: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E6F40),
                          ),
                          blockquote: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF2E6F40),
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: const Color(0xFFF1F7F2),
                            borderRadius: BorderRadius.circular(8),
                            border: const Border(
                              left: BorderSide(color: Color(0xFF2E6F40), width: 3.5),
                            ),
                          ),
                          code: GoogleFonts.robotoMono(
                            fontSize: 12.5,
                            color: const Color(0xFF1B5E20),
                            backgroundColor: const Color(0xFFE8F0E8),
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: const Color(0xFFF3F6F3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD6E2D6)),
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
                          color: const Color(0xFFE5F4EA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.medical_services_rounded, color: Color(0xFF2E6F40), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              "TRỢ LÝ FLORIA KÊ ĐƠN VẬT TƯ ĐIỀU TRỊ",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: const Color(0xFF2E6F40),
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
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: msg.text));
              _showAppToast(
                title: "Đã sao chép vào bộ nhớ tạm",
                subtitle: "Nội dung phản hồi đã sẵn sàng để dán.",
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
                  const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Text(
                    "Sao chép",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
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
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRecommendationCard(String productId) {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final product = shopProvider.getProductById(productId);
    if (product == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8E6C9)),
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
                    color: const Color(0xFF191C19),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.formattedPrice,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E6F40),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFB0BEC5)),
                        ),
                        child: Text(
                          "Chi tiết",
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF455A64)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        shopProvider.addToCart(product);
                        _showAppToast(
                          title: "Đã thêm vào giỏ hàng",
                          subtitle: product.name,
                          icon: Icons.shopping_bag_outlined,
                          iconColor: const Color(0xFF4ADE80),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF364534),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              "Mua ngay",
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

    final targetName = matchingPlant?.nickname ?? widget.plantNameVi ?? "Cây của bạn";

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8E0BE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6F40).withValues(alpha: 0.08),
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
                  color: const Color(0xFF2E6F40).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2E6F40), size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ĐỀ XUẤT LỊCH CHĂM SÓC TỪ TRỢ LÝ FLORIA",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    Text(
                      "Áp dụng cho: $targetName",
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF4B5563), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFD4E8CE), height: 1),
          const SizedBox(height: 10),

          // 3 thông số đề xuất
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCareParamBadge(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF0284C7),
                title: "Tưới nước",
                value: "${proposal.waterDays} ngày/lần",
              ),
              _buildCareParamBadge(
                icon: Icons.science_rounded,
                iconColor: const Color(0xFFD97706),
                title: "Bón phân",
                value: "${proposal.fertilizeDays} ngày/lần",
              ),
              _buildCareParamBadge(
                icon: Icons.eco_rounded,
                iconColor: const Color(0xFF16A34A),
                title: "Lau lá/Soi sâu",
                value: "${proposal.cleanDays} ngày/lần",
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

                      if (context.mounted && success) {
                        setState(() {
                          proposal.isApplied = true;
                        });
                        _showAppToast(
                          title: "Đã cập nhật lịch cho '$targetName'!",
                          subtitle: "Lịch chăm sóc thực tế trong vườn đã đồng bộ theo Trợ lý Floria.",
                          icon: Icons.check_circle_rounded,
                          iconColor: const Color(0xFF4ADE80),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E6F40),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF6B7280),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: proposal.isApplied ? 0 : 2,
              ),
              icon: Icon(
                proposal.isApplied ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                size: 16,
                color: proposal.isApplied ? const Color(0xFF16A34A) : Colors.white,
              ),
              label: Text(
                proposal.isApplied ? "Đã áp dụng vào cây trồng ✓" : "Áp dụng lịch này vào cây",
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
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
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
              color: const Color(0xFF364534).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: Color(0xFF364534), size: 18),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E2DF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF364534),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Đang suy nghĩ...",
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF364534),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE4E2DF))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: const Color(0xFFF7F9F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4E8CE)),
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
                        "Đã đính kèm ảnh cây để Trợ lý Floria chẩn đoán",
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF364534), fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: () => setState(() => _attachedImageBytes = null),
                    ),
                  ],
                ),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF364534)),
                  tooltip: "Chụp ảnh cây",
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_outlined, color: Color(0xFF364534)),
                  tooltip: "Chọn ảnh từ thư viện",
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9F6),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE4E2DF)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1B1C1A)),
                      decoration: InputDecoration(
                        hintText: "Hỏi Trợ lý Floria về sâu bệnh, tưới nước...",
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF747871)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF364534),
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
