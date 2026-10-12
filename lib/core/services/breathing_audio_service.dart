import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dịch vụ phát âm thanh và phản hồi rung cho màn hình tập thở (Box Breathing)
class BreathingAudioService {
  static final BreathingAudioService _instance = BreathingAudioService._internal();
  factory BreathingAudioService() => _instance;
  BreathingAudioService._internal() {
    _initAudio();
  }

  AudioPlayer? _tickPlayer;
  AudioPlayer? _chimePlayer;
  
  Uint8List? _tickWav;
  Uint8List? _chimeWav;
  Uint8List? _completeWav;

  File? _tickFile;
  File? _chimeFile;
  File? _completeFile;

  bool _isInitializing = false;

  /// Đảm bảo dịch vụ âm thanh đã sẵn sàng file WAV trước khi phát
  Future<void> ensureInitialized() async {
    if (_tickFile != null && await _tickFile!.exists() && _chimeFile != null && await _chimeFile!.exists()) {
      return;
    }
    if (_isInitializing) return;
    _isInitializing = true;
    await _initAudio();
    _isInitializing = false;
  }

  Future<void> _initAudio() async {
    try {
      _tickPlayer ??= AudioPlayer();
      _chimePlayer ??= AudioPlayer();

      // Cấu hình phát qua luồng Media (STREAM_MUSIC) để không bị tắt bởi chế độ rung/im lặng
      const androidContext = AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      );
      final audioContext = AudioContext(android: androidContext);
      await _tickPlayer?.setAudioContext(audioContext);
      await _chimePlayer?.setAudioContext(audioContext);

      await _tickPlayer?.setVolume(1.0);
      await _chimePlayer?.setVolume(1.0);

      // Tạo các mẫu âm thanh chuẩn WAV trong bộ nhớ với biên độ rõ nét
      _tickWav = _generateTickWav();
      _chimeWav = _generateChimeWav();
      _completeWav = _generateCompleteWav();

      // Lưu file vào cache tạm để Android MediaPlayer phát trực tiếp 100% ổn định
      final tempDir = Directory.systemTemp;
      _tickFile = File('${tempDir.path}/enigma_breathing_tick.wav');
      _chimeFile = File('${tempDir.path}/enigma_breathing_chime.wav');
      _completeFile = File('${tempDir.path}/enigma_breathing_complete.wav');

      await _tickFile?.writeAsBytes(_tickWav!, flush: true);
      await _chimeFile?.writeAsBytes(_chimeWav!, flush: true);
      await _completeFile?.writeAsBytes(_completeWav!, flush: true);
    } catch (e) {
      debugPrint('[Audio] Error initializing BreathingAudioService: $e');
    }
  }

  /// Phát tiếng tích tắc nhẹ nhàng theo từng giây đếm ngược
  Future<void> playTick({bool enableHaptic = true}) async {
    if (enableHaptic) {
      HapticFeedback.selectionClick();
    }
    
    try {
      await ensureInitialized();
      if (_tickFile != null && await _tickFile!.exists()) {
        await _tickPlayer?.stop();
        await _tickPlayer?.play(DeviceFileSource(_tickFile!.path));
      } else if (_tickWav != null && _tickPlayer != null) {
        await _tickPlayer?.stop();
        await _tickPlayer?.play(BytesSource(_tickWav!));
      } else {
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (e) {
      debugPrint('[Audio] playTick fallback: $e');
      await SystemSound.play(SystemSoundType.click);
    }
  }

  /// Phát âm thanh chuông thanh tịnh khi chuyển giai đoạn thở (Hít vào, Giữ hơi, Thở ra, Thư giãn)
  Future<void> playPhaseChange({bool enableHaptic = true}) async {
    if (enableHaptic) {
      HapticFeedback.mediumImpact();
    }

    try {
      await ensureInitialized();
      if (_chimeFile != null && await _chimeFile!.exists()) {
        await _chimePlayer?.stop();
        await _chimePlayer?.play(DeviceFileSource(_chimeFile!.path));
      } else if (_chimeWav != null && _chimePlayer != null) {
        await _chimePlayer?.stop();
        await _chimePlayer?.play(BytesSource(_chimeWav!));
      } else {
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (e) {
      debugPrint('[Audio] playPhaseChange fallback: $e');
      await SystemSound.play(SystemSoundType.click);
    }
  }

  /// Phát chuông hợp âm kết thúc buổi thở
  Future<void> playComplete({bool enableHaptic = true}) async {
    if (enableHaptic) {
      HapticFeedback.heavyImpact();
    }

    try {
      await ensureInitialized();
      if (_completeFile != null && await _completeFile!.exists()) {
        await _chimePlayer?.stop();
        await _chimePlayer?.play(DeviceFileSource(_completeFile!.path));
      } else if (_completeWav != null && _chimePlayer != null) {
        await _chimePlayer?.stop();
        await _chimePlayer?.play(BytesSource(_completeWav!));
      }
    } catch (e) {
      debugPrint('[Audio] playComplete error: $e');
    }
  }

  /// Dọn dẹp tài nguyên
  void dispose() {
    _tickPlayer?.dispose();
    _chimePlayer?.dispose();
  }

  // ===================== BỘ TẠO FILE ÂM THANH SÓNG WAV (16-bit PCM Mono) =====================

  /// Tạo âm thanh 'tick' gỗ nhẹ, trầm ấm cho mỗi giây (tần số 800Hz hòa âm nhẹ, biên độ 0.85)
  static Uint8List _generateTickWav() {
    const int sampleRate = 44100;
    const double duration = 0.08; // 80ms
    const double frequency = 800.0;
    final int numSamples = (sampleRate * duration).round();
    final Int16List samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double envelope = math.exp(-t * 45.0);
      final double wave = 0.8 * math.sin(2.0 * math.pi * frequency * t) +
          0.2 * math.sin(2.0 * math.pi * (frequency * 1.5) * t);
      final double value = wave * envelope * 0.85;
      samples[i] = (value * 32767).clamp(-32768, 32767).toInt();
    }

    return _createWav(samples, sampleRate);
  }

  /// Tạo tiếng chuông thiền Solfeggio 528Hz ngân vang nhẹ nhàng khi chuyển nhịp (biên độ 0.85)
  static Uint8List _generateChimeWav() {
    const int sampleRate = 44100;
    const double duration = 1.4; // 1.4 giây
    final int numSamples = (sampleRate * duration).round();
    final Int16List samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      // Fade in nhẹ đầu 20ms để không bị tiếng pop
      final double fadeIn = (t / 0.02).clamp(0.0, 1.0);
      final double decay = math.exp(-t * 2.2);
      
      // Tổng hợp hòa âm chuông: 528Hz + 1056Hz + 1584Hz
      final double wave = 0.60 * math.sin(2.0 * math.pi * 528.0 * t) +
          0.25 * math.sin(2.0 * math.pi * 1056.0 * t) +
          0.15 * math.sin(2.0 * math.pi * 1584.0 * t);
          
      final double value = wave * fadeIn * decay * 0.85;
      samples[i] = (value * 32767).clamp(-32768, 32767).toInt();
    }

    return _createWav(samples, sampleRate);
  }

  /// Tạo chuông hợp âm kết thúc (528Hz + 660Hz + 792Hz, biên độ 0.9)
  static Uint8List _generateCompleteWav() {
    const int sampleRate = 44100;
    const double duration = 2.0;
    final int numSamples = (sampleRate * duration).round();
    final Int16List samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double fadeIn = (t / 0.025).clamp(0.0, 1.0);
      final double decay = math.exp(-t * 1.8);
      
      final double wave = 0.45 * math.sin(2.0 * math.pi * 528.0 * t) +
          0.35 * math.sin(2.0 * math.pi * 660.0 * t) +
          0.20 * math.sin(2.0 * math.pi * 792.0 * t);

      final double value = wave * fadeIn * decay * 0.90;
      samples[i] = (value * 32767).clamp(-32768, 32767).toInt();
    }

    return _createWav(samples, sampleRate);
  }

  /// Đóng gói PCM 16-bit Mono thành định dạng WAV chuẩn (RIFF)
  static Uint8List _createWav(Int16List samples, int sampleRate) {
    final int byteRate = sampleRate * 1 * 2; // sampleRate * channels * bytesPerSample
    final int subChunk2Size = samples.length * 2;
    final int chunkSize = 36 + subChunk2Size;

    final ByteData byteData = ByteData(44 + subChunk2Size);

    // RIFF header
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, chunkSize, Endian.little);
    byteData.setUint8(8, 0x57);  // 'W'
    byteData.setUint8(9, 0x41);  // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
    byteData.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, byteRate, Endian.little);
    byteData.setUint16(32, 2, Endian.little);  // BlockAlign (NumChannels * BitsPerSample / 8)
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample (16 bits)

    // data subchunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, subChunk2Size, Endian.little);

    // Sample payload
    int offset = 44;
    for (int i = 0; i < samples.length; i++) {
      byteData.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}
