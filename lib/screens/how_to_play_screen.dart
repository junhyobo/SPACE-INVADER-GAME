import 'package:flutter/material.dart';
import '../assets.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nền
          Image.asset(Assets.bg2, fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.3)),

          // Nội dung
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header + Back
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'HƯỚNG DẪN',
                        style: TextStyle(
                          fontFamily: Assets.titleFontFamily,
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Panel nội dung: LUÔN vừa màn hình, cuộn khi thiếu chỗ
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: LayoutBuilder(
                            builder: (ctx, c) {
                              // bọc nội dung bằng scroll để không tràn
                              return SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _titleRow(Icons.sports_esports, 'CÁCH ĐIỀU KHIỂN'),
                                    const SizedBox(height: 10),
                                    _bullet('• Chạm/chuột:  kéo phi cơ để di chuyển.'),
                                    _bullet('• Chuột trái/đúp chạm: giữ để nhả đạn.'),
                                    _bullet(' playgame : space/(X) =menu '),

                                    const SizedBox(height: 20),
                                    _titleRow(Icons.flag, 'MỤC TIÊU'),
                                    const SizedBox(height: 10),
                                    _bullet('Sống sót, hạ địch, nhặt hộp, giữ combo để điểm cao.'),

                                    const SizedBox(height: 20),
                                    _titleRow(Icons.power, 'VẬT PHẨM'),
                                    const SizedBox(height: 10),
                                    _chipRow(const [
                                      '🟥 Hồi máu',
                                      '🟦 Tăng đạn/cấp',
                                      '🛡️ Khiên',
                                    ]),

                                    const SizedBox(height: 8),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nút đóng: neo dưới, luôn thấy -> không bị đẩy ra ngoài
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.black87, width: 1),
                        ),
                      ),
                      child: const Text(
                        'OK, CHƠI LUÔN',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== helpers (UI nhỏ gọn) =====
  static Widget _titleRow(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
      ],
    );
  }

  static Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        '• $text',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.38,
          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
        ),
      ),
    );
  }

  static Widget _chipRow(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  t,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
