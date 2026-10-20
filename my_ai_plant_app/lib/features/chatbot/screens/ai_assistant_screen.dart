import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/widgets/custom_image.dart';
import '../../shop/providers/shop_provider.dart';
import '../../shop/screens/product_detail_screen.dart';

class ChatMessageItem {
  final bool isUser;
  String text;
  final Uint8List? imageBytes;
  final DateTime timestamp;
  List<String> recommendedProductIds;
  bool isStreaming;

  ChatMessageItem({
    required this.isUser,
    required this.text,
    this.imageBytes,
    DateTime? timestamp,
    this.recommendedProductIds = const [],
    this.isStreaming = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiAssistantScreen extends StatefulWidget {
  final String? plantNameVi;
  final String? scientificName;
  final String? diseaseContext;

  const AiAssistantScreen({
    super.key,
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

  final List<ChatMessageItem> _messages = [];
  final List<Content> _chatHistory = [];

  bool _isLoading = false;
  bool _hasApiKey = false;
  bool _enableDeepThinking = false;
  String _modelName = GeminiService.defaultModel;
  Uint8List? _attachedImageBytes;

  final List<String> _quickPrompts = [
    "Cây bị vàng lá là do đâu?",
    "Bao lâu nên tưới nước một lần?",
    "Lá xuất hiện đốm nâu xử lý thế nào?",
    "Cách bón phân an toàn cho cây trong nhà",
  ];

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _loadThinkingMode();
    _setupPlantSpecificPrompts();
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

  void _toggleDeepThinking(bool isDeep) async {
    setState(() {
      _enableDeepThinking = isDeep;
    });
    await GeminiService.saveDeepThinkingMode(isDeep);
  }

  void _setupPlantSpecificPrompts() {
    if (widget.plantNameVi != null && widget.plantNameVi!.isNotEmpty) {
      final name = widget.plantNameVi!;
      _quickPrompts
        ..clear()
        ..addAll([
          "Lịch tưới & lượng nước cho $name?",
          "Cây $name đặt ở đâu đủ sáng?",
          "Dấu hiệu cây $name bị úng hoặc thiếu nước?",
          "Loại phân bón tốt nhất cho $name?",
          "Các bệnh và sâu hại hay gặp ở $name?",
        ]);
    }
  }

  Future<void> _checkApiKey() async {
    final hasKey = await GeminiService.hasApiKey();
    final model = await GeminiService.getModelName();
    if (mounted) {
      setState(() {
        _hasApiKey = hasKey;
        _modelName = model;
      });
    }
  }

  String _formatModelDisplay(String model) {
    if (model == 'gemini-3-flash-preview') return 'Gemini 3 Flash';
    if (model == 'gemini-3.1-flash-lite') return 'Gemini 3.1 Flash-Lite';
    if (model == 'gemini-3.6-flash') return 'Gemini 3.6 Flash';
    return model;
  }

  void _initWelcomeMessage() {
    String welcome = "Xin chào! Tôi là Bác sĩ Cây trồng Floria AI 🌿\n\nTôi có thể giúp bạn chẩn đoán sâu bệnh, tư vấn lịch tưới nước, ánh sáng và phân bón chuẩn khoa học. Bạn có thể hỏi tôi bất kỳ thắc mắc nào hoặc đính kèm ảnh cây để tôi khám trực tiếp nhé!";
    if (widget.plantNameVi != null && widget.plantNameVi!.isNotEmpty) {
      final sci = widget.scientificName != null && widget.scientificName!.isNotEmpty ? ' (${widget.scientificName})' : '';
      welcome = "Chào bạn! Tôi là Bác sĩ Cây trồng Floria AI 🌿\n\nTôi đang theo dõi chuyên sâu cho cây **${widget.plantNameVi}**$sci của bạn.\n${widget.diseaseContext != null ? '📌 *Tình trạng hiện tại: ${widget.diseaseContext}*\n\n' : '\n'}Tôi đã nạp đầy đủ thông tin sinh học của loài cây này. Bạn cần tôi hướng dẫn cách tưới nước, ánh sáng, nhiệt độ hay chẩn đoán triệu chứng bất thường nào trên cây?";
    }
    _messages.add(ChatMessageItem(isUser: false, text: welcome));
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
            // Ẩn tạm tag sản phẩm trong lúc stream để giao diện không bị giật
            aiPlaceholder.text = accumulated.replaceAll(productRegex, '').trimRight();
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
      final cleanFinal = accumulated.replaceAll(productRegex, '').trim();

      if (mounted) {
        setState(() {
          aiPlaceholder.text = cleanFinal;
          aiPlaceholder.recommendedProductIds = productIds;
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

    } catch (e) {
      if (mounted) {
        setState(() {
          aiPlaceholder.text = "⚠️ Đã có sự cố khi kết nối với Bác sĩ Cây trồng AI: ${e.toString().replaceAll('Exception: ', '')}.\n\nVui lòng kiểm tra lại Google Gemini API Key hoặc kết nối mạng.";
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
                    width: 42,
                    height: 42,
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
                      child: Icon(Icons.psychology, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Bác sĩ Cây trồng AI",
                              style: GoogleFonts.inter(
                                fontSize: 16,
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
                          _hasApiKey
                              ? "Floria ${_formatModelDisplay(_modelName)} • ${_enableDeepThinking ? '🧠 Suy nghĩ sâu' : '⚡ Siêu tốc'}"
                              : "Chưa kích hoạt API Key • Bấm để cài đặt",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _hasApiKey ? const Color(0xFF364534) : Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings_suggest_outlined,
                      color: _hasApiKey ? const Color(0xFF364534) : Colors.amber.shade800,
                    ),
                    tooltip: "Cài đặt Gemini API Key",
                    onPressed: () => GeminiService.showApiKeyDialog(context, onSaved: _checkApiKey),
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

          // Thanh chuyển đổi chế độ Siêu tốc <-> Suy nghĩ sâu
          _buildModeSwitcher(),

          // Danh sách gợi ý câu hỏi nhanh (Quick Prompts)
          _buildQuickPromptsBar(),

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
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _enableDeepThinking ? const Color(0xFF673AB7) : const Color(0xFF2E6F40),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _enableDeepThinking
                                ? "🧠 Bác sĩ đang suy luận y khoa đa tầng..."
                                : "⚡ Bác sĩ đang chẩn đoán tức thì...",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: _enableDeepThinking ? const Color(0xFF5E35B1) : const Color(0xFF2E6F40),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      SelectableText(
                        msg.isStreaming ? "${msg.text} ▍" : msg.text,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          color: const Color(0xFF1B1C1A),
                        ),
                      ),
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
                              "BÁC SĨ AI KÊ ĐƠN VẬT TƯ ĐIỀU TRỊ",
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đã thêm '${product.name}' vào giỏ hàng! 🌿"),
                            backgroundColor: const Color(0xFF2E6F40),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
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
                  "Bác sĩ Cây trồng đang suy nghĩ...",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF747871),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3EE),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDDE3DC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeTabItem(
                  icon: Icons.bolt_rounded,
                  label: "Siêu tốc (~1s)",
                  isSelected: !_enableDeepThinking,
                  activeBgColor: Colors.white,
                  activeTextColor: const Color(0xFF1B5E20),
                  onTap: () => _toggleDeepThinking(false),
                ),
                const SizedBox(width: 4),
                _buildModeTabItem(
                  icon: Icons.psychology_rounded,
                  label: "Suy nghĩ sâu",
                  isSelected: _enableDeepThinking,
                  activeBgColor: const Color(0xFF673AB7),
                  activeTextColor: Colors.white,
                  onTap: () => _toggleDeepThinking(true),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            _enableDeepThinking ? "Phân tích bệnh học đa tầng" : "Tối ưu phản hồi tức thì",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: _enableDeepThinking ? const Color(0xFF673AB7) : const Color(0xFF5A6657),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color activeBgColor,
    required Color activeTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? activeTextColor : const Color(0xFF687466),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeTextColor : const Color(0xFF687466),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPromptsBar() {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _quickPrompts[index];
          return ActionChip(
            label: Text(
              prompt,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF364534),
              ),
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFD4E8CE)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: _isLoading ? null : () => _handleSendMessage(customText: prompt),
          );
        },
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
                        "Đã đính kèm ảnh cây để AI chẩn đoán",
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
                        hintText: "Hỏi bác sĩ cây trồng về sâu bệnh, tưới nước...",
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
