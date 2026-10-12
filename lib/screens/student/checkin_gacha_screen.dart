import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/daily_checkin.dart';
import '../../theme/app_theme.dart';
import '../../core/api/life_log_repository.dart';
import '../../navigation/student_nav.dart';
import 'phq4_screener_screen.dart';

/// Màn hình Điểm Danh + Nhận Thông Điệp Gacha
/// Tích hợp đầy đủ với API backend: điểm danh, streak, gacha message
class CheckinGachaScreen extends StatefulWidget {
  const CheckinGachaScreen({super.key});

  @override
  State<CheckinGachaScreen> createState() => _CheckinGachaScreenState();
}

class _CheckinGachaScreenState extends State<CheckinGachaScreen>
    with TickerProviderStateMixin {
  // State
  bool _hasCheckedIn = false;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _gachaMessage;
  String? _gachaCategory;
  int _currentStreak = 0;
  int _longestStreak = 0;

  // Mood selection state
  String _selectedMood = 'neutral';
  final List<String> _selectedStressFactors = [];

  // Animations
  late AnimationController _spinController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _spinAnimation;
  late Animation<double> _glowAnimation;

  bool _isSpinning = false;

  static const _moods = [
    {'key': 'great', 'emoji': '😄', 'label': 'Tuyệt vời', 'color': 0xFF10B981},
    {'key': 'good', 'emoji': '🙂', 'label': 'Tốt', 'color': 0xFF34D399},
    {'key': 'neutral', 'emoji': '😐', 'label': 'Bình thường', 'color': 0xFFF59E0B},
    {'key': 'tired', 'emoji': '😔', 'label': 'Mệt mỏi', 'color': 0xFFF97316},
    {'key': 'stressed', 'emoji': '😰', 'label': 'Căng thẳng', 'color': 0xFFEF4444},
  ];

  static const _stressFactors = [
    '🏭 Ca đêm', '⏰ Áp lực OT', '🦴 Đau vai gáy',
    '😴 Thiếu ngủ', '🔊 Tiếng ồn', '🏃 Chạy deadline',
    '🤔 Quy trình mới', '🌡️ Nhiệt độ nhà máy',
  ];

  static const _categoryIcons = {
    'motivation': Icons.rocket_launch_rounded,
    'sleep_recovery': Icons.bedtime_rounded,
    'physical_stretch': Icons.fitness_center_rounded,
    'social_connect': Icons.people_rounded,
    'mental_peace': Icons.spa_rounded,
  };

  static const _categoryColors = {
    'motivation': AppTheme.accentAmber,
    'sleep_recovery': AppTheme.sleepColor,
    'physical_stretch': AppTheme.physicalColor,
    'social_connect': AppTheme.socialColor,
    'mental_peace': AppTheme.mentalColor,
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCheckinStatus();
  }

  void _initAnimations() {
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.elasticOut,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _loadCheckinStatus() async {
    try {
      final data = await CheckinRepository.getTodayStatus();
      if (mounted) {
        setState(() {
          _hasCheckedIn = data['has_checked_in'] as bool? ?? false;
          _currentStreak = data['current_streak'] as int? ?? 0;
          _longestStreak = data['longest_streak'] as int? ?? 0;
          if (_hasCheckedIn) {
            _gachaMessage = data['gacha_message'] as String?;
          }
          _isInitialLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _isInitialLoading = false; });
    }
  }

  Future<void> _performCheckin() async {
    if (_isSpinning || _hasCheckedIn) return;

    // Start spin animation
    setState(() { _isSpinning = true; _isLoading = true; });
    _spinController.forward(from: 0);
    _particleController.forward(from: 0);

    try {
      final res = await CheckinRepository.performCheckin(
        mood: _selectedMood,
        stressFactors: _selectedStressFactors,
        note: 'Điểm danh qua app Enigma',
      );

      // Wait for spin animation
      await Future.delayed(const Duration(milliseconds: 1600));

      if (mounted) {
        setState(() {
          _hasCheckedIn = true;
          _gachaMessage = res['gacha_message'] as String?;
          _gachaCategory = _extractCategory(res['gacha_message'] as String? ?? '');
          _currentStreak = res['current_streak'] as int? ?? _currentStreak + 1;
          _longestStreak = res['longest_streak'] as int? ?? _longestStreak;
          _isLoading = false;
          _isSpinning = false;
        });

        MoodLevel appMood = MoodLevel.neutral;
        switch (_selectedMood) {
          case 'great':
            appMood = MoodLevel.great;
            break;
          case 'good':
            appMood = MoodLevel.good;
            break;
          case 'tired':
            appMood = MoodLevel.stressed;
            break;
          case 'stressed':
            appMood = MoodLevel.overwhelmed;
            break;
          default:
            appMood = MoodLevel.neutral;
        }

        // Update AppState streak & refresh dashboard
        context.read<AppState>().recordCheckin(
          appMood,
          _selectedStressFactors,
          'Điểm danh hôm nay',
        );
        context.read<AppState>().triggerRefresh();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _isSpinning = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi điểm danh: $e'),
            backgroundColor: AppTheme.accentCoral,
          ),
        );
      }
    }
  }

  String _extractCategory(String message) {
    if (message.contains('ngủ') || message.contains('Melatonin')) return 'sleep_recovery';
    if (message.contains('giãn cơ') || message.contains('nước')) return 'physical_stretch';
    if (message.contains('Leader') || message.contains('Anh/Chị')) return 'social_connect';
    if (message.contains('hít thở') || message.contains('Box Breathing')) return 'mental_peace';
    return 'motivation';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Điểm Danh Hàng Ngày'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.home_rounded, color: AppTheme.onSurfaceSecondary(context)),
            tooltip: 'Về trang chủ',
            onPressed: () => StudentNav.switchToTab(context, 0),
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Streak Hero Card
                    _buildStreakCard(),
                    const SizedBox(height: 16),

                    // PHQ-4 Medical Screening Banner
                    _buildPHQ4Banner(),
                    const SizedBox(height: 20),

                    if (!_hasCheckedIn) ...[
                      // Mood Selector
                      _buildMoodSelector(),
                      const SizedBox(height: 16),

                      // Stress Factors
                      _buildStressFactorSelector(),
                      const SizedBox(height: 24),

                      // Gacha Wheel & Spin Button
                      _buildGachaWheel(),
                      const SizedBox(height: 20),

                      // Spin Button
                      _buildSpinButton(),
                    ] else ...[
                      // Gacha Message Reveal
                      _buildGachaReveal(),
                      const SizedBox(height: 20),

                      // Done Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.home_rounded, size: 18),
                          label: const Text('Về trang chủ'),
                          onPressed: () => StudentNav.switchToTab(context, 0),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPHQ4Banner() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PHQ4ScreenerScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.14),
                AppTheme.accentMint.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon + Badge + Action Chip
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentMint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'CHUẨN Y KHOA PHQ-4',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentMint,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Làm bài', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              const Text(
                'Sàng lọc sức khỏe tinh thần',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                'Khảo sát nhanh 30 giây chuẩn Đại học Columbia & Viện Y tế Quốc gia Hoa Kỳ (NIH)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceSecondary(context),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentAmber.withOpacity(0.15),
            AppTheme.accentCoral.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Fire streak icon with glow
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (_, child) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentAmber.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentAmber.withOpacity(_glowAnimation.value * 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.local_fire_department_rounded, color: AppTheme.accentAmber, size: 36),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_currentStreak ngày liên tiếp 🔥',
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.accentAmber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kỷ lục: $_longestStreak ngày • Tiếp tục phá vỡ!',
                  style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceSecondary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hôm nay bạn cảm thấy thế nào?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _moods.map((mood) {
            final isSelected = _selectedMood == mood['key'];
            final color = Color(mood['color'] as int);
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood['key'] as String),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : AppTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : AppTheme.borderColor(context),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(mood['emoji'] as String, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(
                      mood['label'] as String,
                      style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600,
                        color: isSelected ? color : AppTheme.onSurfaceMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStressFactorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yếu tố căng thẳng hôm nay? (tuỳ chọn)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            letterSpacing: 0.5, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceSecondary(context),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _stressFactors.map((factor) {
            final isSelected = _selectedStressFactors.contains(factor);
            return GestureDetector(
              onTap: () => setState(() {
                isSelected ? _selectedStressFactors.remove(factor) : _selectedStressFactors.add(factor);
              }),
              child: AnimatedContainer(
                duration: 150.ms,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryLight : AppTheme.borderColor(context),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  factor,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: isSelected ? AppTheme.primaryLight : AppTheme.onSurfaceSecondary(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildGachaWheel() {
    return RepaintBoundary(
      child: Center(
        child: AnimatedBuilder(
        animation: _spinAnimation,
        builder: (_, child) {
          return Transform.rotate(
            angle: _spinAnimation.value * 6.28 * 3, // 3 full rotations
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (_, __) => Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(_glowAnimation.value * 0.5),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            // Wheel body
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppTheme.primary,
                    AppTheme.accentPurple,
                    AppTheme.secondary,
                    AppTheme.accentMint,
                    AppTheme.accentAmber,
                    AppTheme.primary,
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Center icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceColor(context),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentAmber, size: 28),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSpinButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSpinning ? null : _performCheckin,
        icon: _isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.stars_rounded, size: 22),
        label: Text(_isLoading ? 'Đang điểm danh...' : 'Quay & Điểm Danh!'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ).animate(delay: 400.ms).scale(curve: Curves.elasticOut),
    );
  }

  Widget _buildGachaReveal() {
    final category = _gachaCategory ?? 'motivation';
    final iconData = _categoryIcons[category] ?? Icons.auto_awesome_rounded;
    final categoryColor = _categoryColors[category] ?? AppTheme.accentAmber;

    return Column(
      children: [
        // Success Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentMint.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentMint.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.accentMint, size: 24),
              const SizedBox(width: 10),
              Text(
                'Đã điểm danh! Streak: $_currentStreak ngày 🔥',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accentMint, fontSize: 14),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).scale(curve: Curves.elasticOut),

        const SizedBox(height: 20),

        // Gacha Message Card
        if (_gachaMessage != null)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categoryColor.withOpacity(0.15),
                  AppTheme.surfaceColor(context),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: categoryColor.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Animated icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: categoryColor.withOpacity(0.2),
                  ),
                  child: Icon(iconData, color: categoryColor, size: 40),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1500.ms)
                    .then()
                    .shimmer(color: categoryColor.withOpacity(0.3)),

                const SizedBox(height: 20),

                // Particle decorations
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['✨', '🌟', '💫', '⭐', '✨'].map((e) =>
                    Text(e, style: const TextStyle(fontSize: 16))
                      .animate(delay: Duration(milliseconds: _gachaMessage!.length * 5))
                      .scale(curve: Curves.elasticOut)
                  ).toList(),
                ),

                const SizedBox(height: 16),

                // Message text
                Text(
                  _gachaMessage!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    height: 1.6, fontWeight: FontWeight.w600, color: AppTheme.onSurface(context),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Category label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconData, color: categoryColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _getCategoryLabel(category),
                        style: TextStyle(fontSize: 12, color: categoryColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: 200.ms).scale(curve: Curves.elasticOut).fadeIn(),
      ],
    );
  }

  String _getCategoryLabel(String category) {
    const labels = {
      'motivation': 'Động lực',
      'sleep_recovery': 'Giấc ngủ',
      'physical_stretch': 'Thể chất',
      'social_connect': 'Kết nối',
      'mental_peace': 'Bình tâm',
    };
    return labels[category] ?? 'Thông điệp';
  }
}
