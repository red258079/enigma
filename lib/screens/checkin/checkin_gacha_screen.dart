import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/home_provider.dart';

class CheckinGachaScreen extends StatefulWidget {
  const CheckinGachaScreen({super.key});

  @override
  State<CheckinGachaScreen> createState() => _CheckinGachaScreenState();
}

class _CheckinGachaScreenState extends State<CheckinGachaScreen> with SingleTickerProviderStateMixin {
  String _selectedMood = 'Bình ổn tốt';
  final List<String> _selectedFactors = [];
  final _noteController = TextEditingController();

  bool _isRevealed = false;
  String? _revealedMessage;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  final List<Map<String, String>> _moods = [
    {'label': 'Tuyệt vời', 'emoji': '🤩'},
    {'label': 'Bình ổn tốt', 'emoji': '😊'},
    {'label': 'Bình thường', 'emoji': '😐'},
    {'label': 'Mệt mỏi', 'emoji': '😫'},
    {'label': 'Căng thẳng', 'emoji': '😣'},
  ];

  final List<String> _availableFactors = [
    'Ca đêm (20h - 08h)',
    'Đau chân giày ESD',
    'Mỏi vai gáy / Lưng',
    'Kỷ luật 5S nghiêm ngặt',
    'Bất đồng phòng KTX',
    'Ăn uống chưa quen',
    'Nhớ nhà',
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final checkin = Provider.of<CheckinProvider>(context, listen: false);
    final home = Provider.of<HomeProvider>(context, listen: false);

    final msg = await checkin.submitCheckin(
      mood: _selectedMood,
      stressFactors: _selectedFactors,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    home.updateStreak(
      checkin.status?.currentStreak ?? (home.currentStreak + 1),
      checkin.status?.longestStreak ?? (home.longestStreak + 1),
      true,
    );

    setState(() {
      _revealedMessage = msg;
      _isRevealed = true;
    });

    _flipController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final checkin = Provider.of<CheckinProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Điểm danh & Vòng quay Gacha'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: _isRevealed ? _buildRevealedGacha(checkin) : _buildCheckinForm(checkin),
        ),
      ),
    );
  }

  Widget _buildCheckinForm(CheckinProvider checkin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Streak Top Indicator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.streakFire.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chuỗi chuyên cần: ${checkin.status?.currentStreak ?? 5} ngày liên tục',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Điểm danh mỗi ngày để tích lũy kỷ luật và nhận lời khuyên tích cực.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 1. Mood Selection
        const Text(
          '1. Cảm xúc của bạn trước ca làm:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _moods.map((m) {
            final isSelected = _selectedMood == m['label'];
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = m['label']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(m['emoji']!, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(
                      m['label']!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 2. Stress Factors
        const Text(
          '2. Yếu tố tác động hôm nay (chọn nếu có):',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableFactors.map((factor) {
            final isSelected = _selectedFactors.contains(factor);
            return FilterChip(
              label: Text(factor),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedFactors.add(factor);
                  } else {
                    _selectedFactors.remove(factor);
                  }
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 3. Optional Note
        const Text(
          '3. Ghi chú thêm (tùy chọn):',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _noteController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Hôm nay đổi ca mệt, nhưng tổ trưởng khá tận tình...',
          ),
        ),
        const SizedBox(height: 32),

        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: checkin.isLoading ? null : _submit,
            icon: const Icon(Icons.casino_outlined, size: 20),
            label: checkin.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                  )
                : const Text('Xác nhận & Mở hộp Gacha Tinh Thần'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevealedGacha(CheckinProvider checkin) {
    return ScaleTransition(
      scale: _flipAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E2845), Color(0xFF151D33)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primaryLight.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.gachaGold, AppColors.streakFire],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gachaGold.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.black, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'ĐIỂM DANH THÀNH CÔNG! ✨',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.gachaGold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chuỗi ngày liên tục: ${checkin.status?.currentStreak ?? 6} ngày 🔥',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'THÔNG ĐIỆP GACHA TRUYỀN CẢM HỨNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _revealedMessage ?? '“Hãy giữ gìn sức khỏe và luôn tự hào về sự nỗ lực của bản thân mỗi ngày.”',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại Trang chủ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
