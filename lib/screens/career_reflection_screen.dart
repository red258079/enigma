import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CareerReflectionScreen extends StatefulWidget {
  const CareerReflectionScreen({super.key});

  @override
  State<CareerReflectionScreen> createState() => _CareerReflectionScreenState();
}

class _CareerReflectionScreenState extends State<CareerReflectionScreen> {
  int _selectedFitIndex = 1; // 0: Rất thích, 1: Khá phù hợp, 2: Chưa chắc, 3: Không phù hợp, 4: Muốn chuyển hướng
  final Set<String> _acquiredSkills = {'Kỷ luật 5S & Tác phong công nghiệp', 'Hiểu quy trình sản xuất màn hình hiển thị'};
  final Set<String> _neededSkills = {'Tiếng Hàn / Tiếng Anh giao tiếp công xưởng'};

  final List<String> _fitOptions = [
    '❤️ Rất thích môi trường sản xuất công nghệ cao',
    '🙂 Khá phù hợp, học hỏi được nhiều thực tế',
    '😐 Chưa chắc chắn, cần thêm thời gian cân nhắc',
    '😕 Nhận thấy không phù hợp với làm ca/nhà máy',
    '❌ Muốn chuyển hẳn sang hướng ngành khác',
  ];

  final List<String> _allAcquiredOptions = [
    'Kỷ luật 5S & Tác phong công nghiệp',
    'Hiểu quy trình sản xuất màn hình hiển thị',
    'Làm việc nhóm theo ca kíp (Shift teamwork)',
    'Chịu được áp lực năng suất và kỷ luật nghiêm',
    'Kỹ năng quan sát & xử lý lỗi dây chuyền',
  ];

  final List<String> _allNeededOptions = [
    'Tiếng Hàn / Tiếng Anh giao tiếp công xưởng',
    'Kiến thức chuyên sâu Tự động hóa / PLC / Đo kiểm',
    'Kỹ năng viết báo cáo kỹ thuật & thuyết trình',
    'Khả năng quản lý thời gian & cân bằng học - làm',
    'Kỹ năng giải tỏa stress và cân bằng cảm xúc',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Định hướng "What Next?"'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Intro banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.careerColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.careerColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.explore_rounded, color: AppTheme.careerColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phản tư sau 3 tháng tại LG Display',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.careerColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chuyển hóa trải nghiệm thực tế thành lợi thế nghề nghiệp và xác định rõ bước đi tiếp theo.',
                          style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Độ phù hợp
            Text(
              '1. Sau kỳ thực tập, bạn thấy mức độ phù hợp của bản thân thế nào?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface(context),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_fitOptions.length, (idx) {
              final isSelected = _selectedFitIndex == idx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedFitIndex = idx),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.borderColor(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppTheme.primary : AppTheme.onSurfaceMuted(context),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _fitOptions[idx],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? AppTheme.primary : AppTheme.onSurfaceSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Section 2: Giá trị thu hoạch
            Text(
              '2. Những điểm bạn thấy bản thân tiến bộ nhất (Thu hoạch sau 3 tháng):',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface(context),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allAcquiredOptions.map((item) {
                final isSelected = _acquiredSkills.contains(item);
                return FilterChip(
                  label: Text(item),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _acquiredSkills.add(item);
                      } else {
                        _acquiredSkills.remove(item);
                      }
                    });
                  },
                  selectedColor: AppTheme.accentMint.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.accentMint,
                  backgroundColor: AppTheme.surfaceAltColor(context),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppTheme.accentMint : AppTheme.onSurfaceSecondary(context),
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTheme.accentMint : AppTheme.borderColor(context),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Section 3: Lỗ hổng kỹ năng (Skill Gaps)
            Text(
              '3. Lỗ hổng kỹ năng bạn cần ưu tiên bổ sung trong 30-60 ngày tới:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface(context),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allNeededOptions.map((item) {
                final isSelected = _neededSkills.contains(item);
                return FilterChip(
                  label: Text(item),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _neededSkills.add(item);
                      } else {
                        _neededSkills.remove(item);
                      }
                    });
                  },
                  selectedColor: AppTheme.accentAmber.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.accentAmber,
                  backgroundColor: AppTheme.surfaceAltColor(context),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppTheme.accentAmber : AppTheme.onSurfaceSecondary(context),
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTheme.accentAmber : AppTheme.borderColor(context),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Đề xuất hành động
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecorationFor(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Kế hoạch hành động 30 ngày đề xuất',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.onSurface(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• Cập nhật ngay 3 kinh nghiệm thực tế vào CV khi cảm xúc còn mới.\n'
                    '• Dành 20 phút mỗi ngày luyện nghe ngoại ngữ chuyên ngành sản xuất.\n'
                    '• Giữ liên lạc với ít nhất 1 Mentor/Senior kỹ thuật ở LG Display để xin lời khuyên đồ án tốt nghiệp.',
                    style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceSecondary(context), height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã lưu phản tư nghề nghiệp vào hồ sơ cá nhân!'),
                            backgroundColor: AppTheme.accentMint,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Lưu định hướng & Kế hoạch'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
