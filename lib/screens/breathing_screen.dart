import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/breathing_audio_service.dart';
import '../theme/app_theme.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final BreathingAudioService _audioService = BreathingAudioService();

  Timer? _timer;
  int _secondsLeft = 180; // 3 phút
  int _phaseSeconds = 4;
  int _phaseIndex = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold
  bool _isRunning = true;
  bool _isSoundEnabled = true;
  bool _isHapticEnabled = true;

  final List<String> _phases = ['Hít vào nhẹ nhàng', 'Giữ hơi', 'Thở ra chậm rãi', 'Thư giãn'];
  final List<String> _phaseSubtitles = [
    'Hít sâu bằng mũi, căng lồng ngực...',
    'Giữ hơi thở tĩnh lặng...',
    'Thở hết ra qua miệng từ từ...',
    'Thả lỏng toàn bộ cơ vai và mặt...',
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startSession();
  }

  void _startSession() {
    _isRunning = true;
    _controller.forward();
    
    // Phát âm thanh chuông nhẹ mở đầu phiên
    if (_isSoundEnabled) {
      _audioService.playPhaseChange(enableHaptic: _isHapticEnabled);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_secondsLeft <= 0) {
        _timer?.cancel();
        _isRunning = false;
        if (_isSoundEnabled) {
          _audioService.playComplete(enableHaptic: _isHapticEnabled);
        }
        setState(() {});
        return;
      }

      setState(() {
        _secondsLeft--;
        _phaseSeconds--;

        if (_phaseSeconds <= 0) {
          _phaseSeconds = 4;
          _phaseIndex = (_phaseIndex + 1) % 4;

          if (_phaseIndex == 0) {
            _controller.forward(from: 0.0);
          } else if (_phaseIndex == 2) {
            _controller.reverse(from: 1.0);
          }

          // Phát chuông khi chuyển nhịp thở mới
          if (_isSoundEnabled) {
            _audioService.playPhaseChange(enableHaptic: _isHapticEnabled);
          }
        } else {
          // Phát tiếng tích tắc nhẹ mỗi giây
          if (_isSoundEnabled) {
            _audioService.playTick(enableHaptic: _isHapticEnabled);
          }
        }
      });
    });
  }

  void _togglePauseResume() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _controller.stop();
        _isRunning = false;
      } else {
        if (_secondsLeft > 0) {
          _startSession();
        } else {
          _restartSession();
        }
      }
    });
  }

  void _restartSession() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 180;
      _phaseSeconds = 4;
      _phaseIndex = 0;
      _controller.reset();
    });
    _startSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kỹ thuật Thở Hộp'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isHapticEnabled ? Icons.vibration_rounded : Icons.phone_android_rounded,
              color: _isHapticEnabled ? AppTheme.accentMint : AppTheme.onSurfaceSecondary(context),
            ),
            tooltip: _isHapticEnabled ? 'Tắt phản hồi rung' : 'Bật phản hồi rung',
            onPressed: () {
              setState(() {
                _isHapticEnabled = !_isHapticEnabled;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _isSoundEnabled ? AppTheme.accentMint : AppTheme.onSurfaceSecondary(context),
            ),
            tooltip: _isSoundEnabled ? 'Tắt âm thanh đếm nhịp' : 'Bật âm thanh đếm nhịp',
            onPressed: () {
              setState(() {
                _isSoundEnabled = !_isSoundEnabled;
              });
              if (_isSoundEnabled) {
                _audioService.playPhaseChange(enableHaptic: _isHapticEnabled);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Timer header & Sound indicator badge (bọc Wrap chống overflow trên mọi màn hình)
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceAltColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppTheme.onSurfaceSecondary(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Còn lại: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _isSoundEnabled = !_isSoundEnabled;
                      });
                      if (_isSoundEnabled) {
                        _audioService.playPhaseChange(enableHaptic: _isHapticEnabled);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isSoundEnabled 
                            ? AppTheme.accentMint.withValues(alpha: 0.15)
                            : AppTheme.surfaceAltColor(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isSoundEnabled 
                              ? AppTheme.accentMint.withValues(alpha: 0.5) 
                              : AppTheme.borderColor(context),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            size: 16,
                            color: _isSoundEnabled ? AppTheme.accentMint : AppTheme.onSurfaceSecondary(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isSoundEnabled ? 'Âm thanh: Bật' : 'Âm thanh: Tắt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isSoundEnabled ? AppTheme.accentMint : AppTheme.onSurfaceSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Breathing Visualizer
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _phaseIndex == 1
                        ? 1.2
                        : _phaseIndex == 3
                            ? 0.7
                            : _scaleAnimation.value,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accentMint.withValues(alpha: 0.35),
                            AppTheme.primary.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: AppTheme.accentMint.withValues(alpha: 0.7),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentMint.withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_phaseSeconds',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onSurface(context),
                              ),
                            ),
                            Text(
                              'giây',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.onSurfaceSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 36),

              // Phase text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey<int>(_phaseIndex),
                  children: [
                    Text(
                      _phases[_phaseIndex],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentMint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _phaseSubtitles[_phaseIndex],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurfaceSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Control buttons (Play/Pause & Reset)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: _restartSession,
                    icon: const Icon(Icons.replay_rounded),
                    tooltip: 'Bắt đầu lại',
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _togglePauseResume,
                    icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(_isRunning ? 'Tạm dừng' : 'Tiếp tục'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentMint,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Information card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecorationFor(context),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.accentAmber, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kỹ thuật thở 4-4-4-4 được áp dụng rộng rãi giúp hạ cortisol, xoa dịu thần kinh sau ca làm việc căng thẳng.',
                        style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceSecondary(context)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
