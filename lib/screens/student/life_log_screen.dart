import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/api/life_log_repository.dart';

/// Màn hình Ghi Nhật Ký Sinh Hoạt — giờ ngủ, mức stress, triệu chứng
class LifeLogScreen extends StatefulWidget {
  const LifeLogScreen({super.key});

  @override
  State<LifeLogScreen> createState() => _LifeLogScreenState();
}

class _LifeLogScreenState extends State<LifeLogScreen> with TickerProviderStateMixin {
  // Form values
  int _stressLevel = 2;
  double _sleepHours = 7.0;
  String? _shiftType;
  final List<String> _selectedSymptoms = [];
  final _noteController = TextEditingController();
  int? _waterIntakeMl;

  // States
  bool _isLoading = false;
  bool _isSaved = false;
  Map<String, dynamic>? _savedResult;

  // Tab controller for history vs new entry
  late TabController _tabController;

  // Pre-loaded history
  List<Map<String, dynamic>> _history = [];
  bool _historyLoading = true;

  static const _symptoms = [
    {'icon': '🦴', 'label': 'Đau vai gáy'},
    {'icon': '🔩', 'label': 'Đau lưng'},
    {'icon': '😵', 'label': 'Đau đầu'},
    {'icon': '👁️', 'label': 'Mỏi mắt'},
    {'icon': '🦶', 'label': 'Đau chân'},
    {'icon': '🌡️', 'label': 'Chóng mặt'},
    {'icon': '🤢', 'label': 'Buồn nôn'},
    {'icon': '💤', 'label': 'Ngủ gật'},
  ];

  static const _stressLabels = ['', 'Bình thản 😌', 'Nhẹ nhàng 🙂', 'Trung bình 😐', 'Căng thẳng 😟', 'Rất căng 😰'];
  static const _stressColors = [
    Colors.transparent,
    AppTheme.accentMint,
    Color(0xFF34D399),
    AppTheme.accentAmber,
    Color(0xFFF97316),
    AppTheme.accentCoral,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await LifeLogRepository.getHistory(days: 7);
      final entries = (data['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() { _history = entries; _historyLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _historyLoading = false; });
    }
  }

  Future<void> _saveLifeLog() async {
    setState(() { _isLoading = true; });

    try {
      final result = await LifeLogRepository.createLifeLog(
        stressLevel: _stressLevel,
        sleepHours: _sleepHours,
        shiftType: _shiftType,
        physicalSymptoms: _selectedSymptoms,
        moodNote: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        waterIntakeMl: _waterIntakeMl,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSaved = true;
          _savedResult = result;
        });
        _loadHistory(); // Refresh history
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.accentCoral),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nhật Ký Sinh Hoạt'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.onSurface(context),
          unselectedLabelColor: AppTheme.onSurfaceMuted(context),
          tabs: const [
            Tab(text: 'Ghi hôm nay', icon: Icon(Icons.edit_rounded, size: 18)),
            Tab(text: 'Lịch sử', icon: Icon(Icons.history_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isSaved ? _buildSavedView() : _buildEntryForm(),
          _buildHistoryView(),
        ],
      ),
    );
  }

  // ─── Entry Form ─────────────────────────────────────────────────────────────

  Widget _buildEntryForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('💤 Số giờ ngủ ca vừa rồi', '${_sleepHours.toStringAsFixed(1)}h'),
          const SizedBox(height: 12),
          _buildSleepSlider(),

          const SizedBox(height: 24),

          _buildSectionHeader('🧠 Mức độ căng thẳng', _stressLabels[_stressLevel]),
          const SizedBox(height: 12),
          _buildStressSelector(),

          const SizedBox(height: 24),

          _buildSectionHeader('🏭 Loại ca làm việc', _shiftType == 'day' ? 'Ca ngày ☀️' : _shiftType == 'night' ? 'Ca đêm 🌙' : 'Chưa chọn'),
          const SizedBox(height: 12),
          _buildShiftSelector(),

          const SizedBox(height: 24),

          _buildSectionHeader('🦴 Triệu chứng thể chất', '${_selectedSymptoms.length} đã chọn'),
          const SizedBox(height: 12),
          _buildSymptomsGrid(),

          const SizedBox(height: 24),

          _buildSectionHeader('💧 Lượng nước uống', _waterIntakeMl != null ? '${_waterIntakeMl}ml' : 'Chưa ghi'),
          const SizedBox(height: 12),
          _buildWaterSelector(),

          const SizedBox(height: 24),

          _buildSectionHeader('📝 Ghi chú tâm trạng', ''),
          const SizedBox(height: 12),
          _buildNoteField(),

          const SizedBox(height: 32),
          _buildSaveButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        if (value.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.primaryLight, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildSleepSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecorationFor(context),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _sleepColor(_sleepHours),
              thumbColor: _sleepColor(_sleepHours),
              inactiveTrackColor: AppTheme.borderColor(context),
              overlayColor: _sleepColor(_sleepHours).withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _sleepHours,
              min: 0,
              max: 12,
              divisions: 24,
              onChanged: (v) => setState(() => _sleepHours = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0h', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted(context))),
              Text(_sleepQualityLabel(_sleepHours), style: TextStyle(fontSize: 12, color: _sleepColor(_sleepHours), fontWeight: FontWeight.w600)),
              Text('12h', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStressSelector() {
    return Row(
      children: List.generate(5, (i) {
        final level = i + 1;
        final isSelected = _stressLevel == level;
        final color = _stressColors[level];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _stressLevel = level),
            child: AnimatedContainer(
              duration: 200.ms,
              margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? color : AppTheme.borderColor(context), width: isSelected ? 2 : 1),
              ),
              child: Column(
                children: [
                  Text('$level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isSelected ? color : AppTheme.onSurfaceMuted(context))),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildShiftSelector() {
    return Row(
      children: [
        Expanded(child: _buildShiftChip('day', '☀️ Ca ngày', AppTheme.accentAmber)),
        const SizedBox(width: 12),
        Expanded(child: _buildShiftChip('night', '🌙 Ca đêm', AppTheme.sleepColor)),
      ],
    );
  }

  Widget _buildShiftChip(String type, String label, Color color) {
    final isSelected = _shiftType == type;
    return GestureDetector(
      onTap: () => setState(() => _shiftType = isSelected ? null : type),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : AppTheme.borderColor(context), width: isSelected ? 2 : 1),
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? color : AppTheme.onSurfaceSecondary(context), fontSize: 14)),
      ),
    );
  }

  Widget _buildSymptomsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _symptoms.map((s) {
        final label = s['label']!;
        final emoji = s['icon']!;
        final isSelected = _selectedSymptoms.contains(label);
        return GestureDetector(
          onTap: () => setState(() {
            isSelected ? _selectedSymptoms.remove(label) : _selectedSymptoms.add(label);
          }),
          child: AnimatedContainer(
            duration: 150.ms,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentCoral.withOpacity(0.15) : AppTheme.surfaceColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppTheme.accentCoral : AppTheme.borderColor(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, color: isSelected ? AppTheme.accentCoral : AppTheme.onSurfaceSecondary(context), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWaterSelector() {
    final options = [500, 1000, 1500, 2000, 2500];
    return Row(
      children: options.map((ml) {
        final isSelected = _waterIntakeMl == ml;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _waterIntakeMl = isSelected ? null : ml),
            child: AnimatedContainer(
              duration: 150.ms,
              margin: EdgeInsets.only(right: ml < 2500 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.secondary.withOpacity(0.15) : AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? AppTheme.secondary : AppTheme.borderColor(context)),
              ),
              child: Column(children: [
                Text('💧', style: TextStyle(fontSize: isSelected ? 18 : 14)),
                Text(ml ~/ 1000 > 0 ? '${ml / 1000}L' : '${ml}ml',
                  style: TextStyle(fontSize: 10, color: isSelected ? AppTheme.secondary : AppTheme.onSurfaceMuted(context), fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      maxLength: 1000,
      style: TextStyle(color: AppTheme.onSurface(context), fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Ghi lại cảm xúc, suy nghĩ, hoặc sự kiện đặc biệt trong ca hôm nay...',
        hintStyle: TextStyle(color: AppTheme.onSurfaceMuted(context), fontSize: 13),
        filled: true,
        fillColor: AppTheme.surfaceAltColor(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor(context))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor(context))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryLight)),
        counterStyle: TextStyle(color: AppTheme.onSurfaceMuted(context), fontSize: 11),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveLifeLog,
        icon: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save_rounded),
        label: Text(_isLoading ? 'Đang lưu...' : 'Lưu Nhật Ký Hôm Nay'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ─── Saved View ─────────────────────────────────────────────────────────────

  Widget _buildSavedView() {
    final result = _savedResult;
    if (result == null) return const SizedBox.shrink();

    final riskLevel = (result['risk_assessment'] as Map?)?['level'] as String? ?? 'GREEN';
    final wellbeingScore = result['wellbeing_score'] as int? ?? 70;
    final stressDesc = result['stress_description'] as Map? ?? {};
    final sleepQuality = result['sleep_quality'] as Map? ?? {};
    final riskActions = ((result['risk_assessment'] as Map?)?['recommended_actions'] as List?)?.cast<String>() ?? [];

    Color riskColor = AppTheme.accentMint;
    String riskEmoji = '✅';
    if (riskLevel == 'YELLOW') { riskColor = AppTheme.accentAmber; riskEmoji = '⚠️'; }
    if (riskLevel == 'RED') { riskColor = AppTheme.accentCoral; riskEmoji = '🆘'; }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Success header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.accentMint.withOpacity(0.12), AppTheme.surfaceColor(context)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentMint.withOpacity(0.3)),
            ),
            child: Column(children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.accentMint, size: 48),
              const SizedBox(height: 12),
              Text('Đã lưu nhật ký hôm nay!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.onSurface(context))),
              const SizedBox(height: 8),
              Text('Điểm sức khỏe hôm nay: $wellbeingScore/100',
                style: TextStyle(fontSize: 14, color: _wellbeingColor(wellbeingScore), fontWeight: FontWeight.w600)),
            ]),
          ).animate().fadeIn(duration: 500.ms).scale(curve: Curves.elasticOut),

          const SizedBox(height: 16),

          // Metrics row
          Row(children: [
            Expanded(child: _buildResultMetric('Stress', stressDesc['emoji'] as String? ?? '😐', stressDesc['label'] as String? ?? '', riskColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildResultMetric('Giấc ngủ', '💤', sleepQuality['label'] as String? ?? '', AppTheme.sleepColor)),
          ]),

          const SizedBox(height: 16),

          // AI Risk Assessment
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: riskColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(riskEmoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('AI Agent đánh giá: $riskLevel', style: TextStyle(fontWeight: FontWeight.w700, color: riskColor, fontSize: 14)),
                ]),
                if (riskActions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...riskActions.take(3).map((action) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.arrow_right_rounded, color: riskColor, size: 18),
                      Expanded(child: Text(action, style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceSecondary(context), height: 1.4))),
                    ]),
                  )),
                ],
              ],
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Ghi lại (xoá & làm mới)'),
              onPressed: () => setState(() { _isSaved = false; _savedResult = null; }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultMetric(String label, String emoji, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted(context))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // ─── History View ────────────────────────────────────────────────────────────

  Widget _buildHistoryView() {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_history.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history_rounded, color: AppTheme.onSurfaceMuted(context), size: 60),
          const SizedBox(height: 12),
          Text('Chưa có nhật ký nào', style: TextStyle(color: AppTheme.onSurfaceMuted(context), fontSize: 16)),
          const SizedBox(height: 8),
          Text('Bắt đầu ghi hôm nay để theo dõi sức khỏe!', style: TextStyle(color: AppTheme.onSurfaceMuted(context), fontSize: 12)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (ctx, i) {
        final entry = _history[i];
        return _buildHistoryCard(entry);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final stressColor = Color(int.parse('0xFF${_stressHex(entry['stress_level'] as int? ?? 2)}'));
    final sleepColor = _sleepColor(entry['sleep_hours'] as double? ?? 7.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecorationFor(context),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(shape: BoxShape.circle, color: stressColor.withOpacity(0.15)),
          child: Center(child: Text(entry['stress_emoji'] as String? ?? '😐', style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry['date'] as String? ?? '', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted(context))),
          const SizedBox(height: 3),
          Row(children: [
            Icon(Icons.psychology_rounded, color: stressColor, size: 14),
            const SizedBox(width: 4),
            Text(entry['stress_label'] as String? ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stressColor)),
            const SizedBox(width: 12),
            Icon(Icons.bedtime_rounded, color: sleepColor, size: 14),
            const SizedBox(width: 4),
            Text('${(entry['sleep_hours'] as double? ?? 0).toStringAsFixed(1)}h', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sleepColor)),
          ]),
          if ((entry['physical_symptoms'] as List?)?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Triệu chứng: ${(entry['physical_symptoms'] as List).join(", ")}',
                style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.surfaceAltColor(context), borderRadius: BorderRadius.circular(8)),
          child: Text(entry['ai_sentiment'] as String? ?? 'neutral', style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceSecondary(context))),
        ),
      ]),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  Color _sleepColor(double hours) {
    if (hours >= 8) return AppTheme.accentMint;
    if (hours >= 7) return const Color(0xFF34D399);
    if (hours >= 6) return AppTheme.accentAmber;
    return AppTheme.accentCoral;
  }

  String _sleepQualityLabel(double hours) {
    if (hours >= 8) return 'Tuyệt vời ✨';
    if (hours >= 7) return 'Tốt 👍';
    if (hours >= 6) return 'Tạm ổn 😐';
    if (hours >= 5) return 'Thiếu ngủ 😟';
    return 'Rất thiếu ngủ 😰';
  }

  Color _wellbeingColor(int score) {
    if (score >= 80) return AppTheme.accentMint;
    if (score >= 60) return AppTheme.accentAmber;
    return AppTheme.accentCoral;
  }

  String _stressHex(int level) {
    const hexes = ['', '10B981', '34D399', 'F59E0B', 'F97316', 'EF4444'];
    return level > 0 && level <= 5 ? hexes[level] : 'F59E0B';
  }
}
