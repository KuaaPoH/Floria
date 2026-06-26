import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../profile/screens/premium_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 4))
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF3B4A3D), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      image: const DecorationImage(
                        image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuB5zVt1CIeekQEpNepKUd9D2tCaheeYaMLwMR8eDFdG2u_8IVM-klq50UmxW6LoqhseO8M548hIdUovyLTUBUgYHOENz9JfURxXETJ5OXuMDkBGdkjU5sI_dRr2O3ilAP6BegaqUFSShMw5yrozV3PfGjUval__xuFypTxY_tWBNar1CjpLp1pdhUxFsNjRE5tuhlBfOY8GrwxsuXXI2SzsCzh0BsYjNRCs83UsUWO-ht6IShf0bJG1_aJheThzyICMTgkEsha_aks"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Bác sĩ Cây trồng AI",
                          style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF151E16)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Text("Floria DeepVision", style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF3B4A3D))),
                                  const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF3B4A3D)),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF3B4A3D)),
                    onPressed: () {},
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                _buildContextBar(),
                const SizedBox(height: 24),
                _buildAIBubble("Chào bạn! Với tình trạng cháy viền ở cây Trầu Bà, bạn có thể mô tả thêm về môi trường sống hiện tại của cây không? Ví dụ như lượng nước tưới, ánh sáng, hoặc có sử dụng phân bón gần đây không?"),
                const SizedBox(height: 16),
                _buildUserBubble("Lá cây trầu bà bị cháy viền thì có cần phun thuốc ngay không bợt?"),
                const SizedBox(height: 16),
                _buildTypingIndicator(),
              ],
            ),
          ),
          _buildInputDock(),
        ],
      ),
    );
  }

  Widget _buildContextBar() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_florist, size: 16, color: Color(0xFF006D35)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "Đang trò chuyện về: Cây Trầu Bà (Bệnh Đốm Lá)",
                style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF3B4A3D)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBubble(String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(bottom: 4, right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: const DecorationImage(
              image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuDqqA6miNtiN2oZhCs2AtAA0U52t1AOkHDZQ9xgRpNWVOTIVjwM3beLe-KIR6RVYyBTyqGszed_tooBzLb1rosZLviy2CihlsWJezqqQwCaODLVlr2SFA6JrFjLjYFyFPkgb3idYbdb1P2xlymHoRq4yxlSmsBs7RO2CNI7sGaomUyKOWhqbWo1B5fYAKqOzD-i_uEtiVzzbf1q0rYqCou7pbwHZtxzcleFpEv2RzlexiPA2u-u0ppoOhwa0q6rK045KnDreND32fM"),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.beVietnamPro(fontSize: 15, height: 1.5, color: const Color(0xFF151E16)),
            ),
          ),
        ),
        const SizedBox(width: 40), // Spacer
      ],
    );
  }

  Widget _buildUserBubble(String message) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 60), // Spacer
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 4))
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.beVietnamPro(fontSize: 15, height: 1.5, color: const Color(0xFF00612E)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(bottom: 4, right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: const DecorationImage(
              image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuBkSg_kKM_XG31OnBoP0Efcu_jxYj-orAvD6fLBebvmXZ06TMzJUGOzvZog_9JH06tYHiOPqSkKagMIbd2arkQybKfYZYZSFKA8fk2CtysPEZDLPRFJRmMlDgk-4F52_E3Kb_cPJw35aaWT0R7oG0TUmgnMl3fP7DadHVdlwWgPq9jask1c5ur0k0Lz7QZudZaltt2h2rkUdBP9-blQJzHoL9l9mZ21Y4oc-3OwmFQL5tQChG-A5U0h3CjUtGGJcQ_xURQZ_PIGfyA"),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(0),
              const SizedBox(width: 4),
              _buildDot(150),
              const SizedBox(width: 4),
              _buildDot(300),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int delayMs) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF006D35),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputDock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 32, offset: const Offset(0, -8))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Color(0xFF3B4A3D)),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  style: GoogleFonts.beVietnamPro(fontSize: 15, color: const Color(0xFF151E16)),
                  decoration: InputDecoration(
                    hintText: "Hỏi chuyên gia về cách chữa trị...",
                    hintStyle: GoogleFonts.beVietnamPro(fontSize: 15, color: const Color(0xFF3B4A3D).withValues(alpha: 0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF00612E)),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
