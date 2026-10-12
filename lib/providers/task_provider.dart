import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _isLoading = false;
  String _selectedPhase = 'adaptation'; // preparation, adaptation, sustain
  List<TaskModel> _tasks = [];

  bool get isLoading => _isLoading;
  String get selectedPhase => _selectedPhase;
  List<TaskModel> get tasks => _tasks;

  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  double get progressPercentage => _tasks.isEmpty ? 0.0 : (completedCount / _tasks.length);

  void setPhase(String phase) {
    if (_selectedPhase != phase) {
      _selectedPhase = phase;
      fetchTasks();
    }
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get('${ApiConstants.tasks}?phase=$_selectedPhase');
      if (res.statusCode == 200) {
        final list = res.data as List<dynamic>;
        _tasks = list.map((e) => TaskModel.fromJson(e)).toList();
      }
    } catch (_) {
      // Local fallback initial tasks for 3 phases
      _tasks = _getFallbackTasks(_selectedPhase);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTask(TaskModel task) async {
    task.isCompleted = !task.isCompleted;
    notifyListeners();

    try {
      await _api.dio.post(ApiConstants.taskToggle(task.id));
    } catch (_) {
      // Keep optimistic update even offline
    }
  }

  List<TaskModel> _getFallbackTasks(String phase) {
    switch (phase) {
      case 'preparation':
        return [
          TaskModel(
            id: 'prep-1',
            title: 'Mua miếng lót giày silicon giảm áp lực ESD',
            description: 'Trang bị trước để không bị đau nhức gan bàn chân khi đứng ca 12 tiếng.',
            phase: 'preparation',
            pillar: 'physical',
            isCompleted: true,
          ),
          TaskModel(
            id: 'prep-2',
            title: 'Chuẩn bị rèm cản sáng & bịt mắt ngủ',
            description: 'Cần thiết để có thể ngủ sâu ban ngày khi đổi sang ca đêm.',
            phase: 'preparation',
            pillar: 'sleep',
            isCompleted: true,
          ),
          TaskModel(
            id: 'prep-3',
            title: 'Đọc kỹ hợp đồng thực tập & nội quy nhà máy',
            description: 'Nắm vững quyền lợi, phụ cấp ca đêm và quy tắc an toàn.',
            phase: 'preparation',
            pillar: 'career',
            isCompleted: false,
          ),
        ];
      case 'adaptation':
        return [
          TaskModel(
            id: 'adap-1',
            title: 'Học thuộc quy tắc 5S trong khu vực thao tác',
            description: 'Sàng lọc - Sắp xếp - Sạch sẽ - Săn sóc - Sẵn sàng.',
            phase: 'adaptation',
            pillar: 'career',
            isCompleted: true,
          ),
          TaskModel(
            id: 'adap-2',
            title: 'Luyện tập kỹ thuật thở Box Breathing 4-4-4-4',
            description: 'Giải tỏa lo âu tức thì khi gặp sự cố máy hoặc bị nhắc nhở.',
            phase: 'adaptation',
            pillar: 'mental',
            isCompleted: true,
          ),
          TaskModel(
            id: 'adap-3',
            title: 'Thỏa thuận giờ yên tĩnh với bạn cùng phòng KTX',
            description: 'Tránh mâu thuẫn giờ giấc khi hai người làm việc lệch ca.',
            phase: 'adaptation',
            pillar: 'social',
            isCompleted: false,
          ),
          TaskModel(
            id: 'adap-4',
            title: 'Thực hiện ngâm chân nước ấm & giãn cơ sau ca',
            description: 'Giảm phù nề và nhức mỏi bắp chân sau ca đứng dài.',
            phase: 'adaptation',
            pillar: 'physical',
            isCompleted: false,
          ),
        ];
      case 'sustain':
        return [
          TaskModel(
            id: 'sus-1',
            title: 'Ghi nhật ký học hỏi kỹ thuật hàng tuần',
            description: 'Thu thập số liệu thực tế để phục vụ báo cáo tốt nghiệp.',
            phase: 'sustain',
            pillar: 'career',
            isCompleted: false,
          ),
          TaskModel(
            id: 'sus-2',
            title: 'Duy trì nhịp sinh hoạt ổn định cuối tuần',
            description: 'Không thức thâu đêm ngày nghỉ để tránh sốc nhịp sinh học ca tiếp theo.',
            phase: 'sustain',
            pillar: 'sleep',
            isCompleted: false,
          ),
          TaskModel(
            id: 'sus-3',
            title: 'Tham gia hoạt động thể thao cùng tổ sản xuất',
            description: 'Tăng cường sự gắn kết và tinh thần đồng đội.',
            phase: 'sustain',
            pillar: 'social',
            isCompleted: false,
          ),
        ];
      default:
        return [];
    }
  }
}
