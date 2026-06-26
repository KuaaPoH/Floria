import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlantDiaryScreen extends StatelessWidget {
  const PlantDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF006D35)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nhật Ký Sinh Trưởng',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF006D35),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF006D35).withValues(alpha: 0.2)),
                image: const DecorationImage(
                  image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuDemLqKWqMxeR-gRWoWPkZiP48KvPLsSAIX7j7MOsK470A-XlwaX1yuRwY5RvPnhzfD-gTUd89gKAvh0s1p7dCGKhoCmeWAzRsRkjYN6tNKXd3UqVv3-yOyx7BobE8SWhNVhSD-mP5kEblmLc9oSgHLQ95oOkEhMo4OhLWiBI3r5iA-lpC72zxt4m5yFpgaQH9jqOkacjb-D9pIMXJxx4vSK05jBQan1QcqVQdc7ivhLDutoaCGrWIOp39IyW26zyLzUAc9QRa-KHk"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Vertical Timeline Line
          Positioned(
            left: 36,
            top: 20,
            bottom: 40,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF00E676), Color(0xFF006D35)],
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.only(top: 20, bottom: 100, right: 20),
            children: [
              _buildTimelineItem(
                context,
                date: "15/06/2026",
                title: "Phát hiện Bệnh Đốm Lá",
                description: "Đã áp dụng phác đồ trị nấm Bio-Shield định kỳ 2 lần/tuần.",
                dotColor: Colors.red,
                tag: "Đã khỏi bệnh",
                isError: true,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services, color: Colors.red),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phác đồ điều trị", style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                          Text("Bio-Shield Nano Silver v2.0", style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.black87)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildTimelineItem(
                context,
                date: "01/05/2026",
                title: "Đổi chậu mới & Thêm đất",
                description: "Cây phát triển nhanh, rễ bắt đầu bó hẹp nên đã chuyển sang chậu sứ size L (30cm).",
                dotColor: const Color(0xFF006D35),
                isError: false,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildImageGridItem("https://lh3.googleusercontent.com/aida-public/AB6AXuDGol63XhseWfCmzAWVCJv2QhcPwKcGowE9hKUhybcQsNU8qcyMKSehYSllMebdJuXcyVM9Mt9Q5Zju-Zk3dOtI-f5F5BW2F_O127mVhgefdWpdmfH-3FOxXKB7BpeHrdmqpcrPMzUqNN1KvnTDTD3-VsOUzHmeOmkLl-iDbAfLLYfmmRHoCXRtGyXi5CjqWPZKnR48G0Vocmo4s-Akvre-IdKfygrLvsqRfubG6Xd4D6CQ0drpbLNBfGTW-dftYru1tiFRnuCYSE4"),
                      _buildImageGridItem("https://lh3.googleusercontent.com/aida-public/AB6AXuCQFXe_5MPdz5Ap0LArVgJvshhu_dlEj3CSVHyyrIQbJgdd_jv2PUKolvYcIOyJSk_Dk3bJxwSvx1M_MsSUEeePGrd2Fnbor37kz7dd4q1xBVf80o6D2P_Ry8GkvhaIHRWkVDGKxn3tpPqMmNMpmkt7m2LgbGDxFbC-HTPLB-QV2xzxRjChJKuegosIEPxpQciYbw5aeayMR-f9dIig2rGKqe9fOtFDfbVUDBBBzMqLg6tiUPEIGcl99GB8x8eRlgD4b3DHdBzkP5E"),
                      _buildImageGridItem("https://lh3.googleusercontent.com/aida-public/AB6AXuDKOQePztq7UQCF48cIWoWeCmWMMqp5QDUo0AmyfOLtqRw3ky3ARy19Y7sb5GNk38DekNAhaBZrSayqweRYOIr0uyqDZlycWQ1QVFba1EZwMH5ECwzZl1tNpcVmkghfI2Q9ldna3RFQzPwNYsonSiUiNCTJleJ1XrjwPREUL2BcaUJnkjuYmx9a9lW_atsdCWuB7E59xD72JcGFNPHFJt1Nm8LszZtz_ed2CiS1fEN3UYFuWUMM0KkV29tWC7l8O3HRX0OjiZ0ULww"),
                      Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImageGridItem("https://lh3.googleusercontent.com/aida-public/AB6AXuAKgdjHssSyLgFbRE48NZhKG58kZBgXOltG9Z8O1ebQ-zWXa9PH06H-JhUPHXT6Rl1N1yWuqKZ_mVYIJC-Nr6L2AAaEZUqWtV3HR1NSiJDXrGxP6oK4rMf8r6jq_kLIgjT_suLASRL1EKS37MXgK-5WA54CTAHe1AsT9OFOi6cMQjRvZgMTU8LwY5c-hHTNkagRSXBdiReTb24YDVbxGV8Y2xk3IkxGOBS5X2JwSCLsrVX_EhU3MFZvXq-IFE6JgTN7yeh5aHuk20s"),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text("+12", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF00E676),
        child: const Icon(Icons.add, color: Color(0xFF006D35)),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, {
    required String date,
    required String title,
    required String description,
    required Color dotColor,
    String? tag,
    required bool isError,
    Widget? child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dot Indicator
          Positioned(
            left: -32,
            top: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: dotColor.withValues(alpha: 0.3), width: 4),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Color(0xFF3B4A3D)),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF3B4A3D)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border(left: BorderSide(color: isError ? Colors.red : Colors.transparent, width: 4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isError ? Colors.red : const Color(0xFF006D35),
                            ),
                          ),
                        ),
                        if (tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006D35).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag.toUpperCase(),
                              style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF006D35)),
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: GoogleFonts.beVietnamPro(fontSize: 14, color: const Color(0xFF3B4A3D)),
                    ),
                    ?child,
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGridItem(String url) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
