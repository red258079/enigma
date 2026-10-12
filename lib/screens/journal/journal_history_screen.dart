import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/journal_model.dart';
import '../../providers/journal_provider.dart';

class JournalHistoryScreen extends StatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  State<JournalHistoryScreen> createState() => _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends State<JournalHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JournalProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final journal = Provider.of<JournalProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử Nhật ký Tâm lý'),
      ),
      body: SafeArea(
        child: journal.isLoading && journal.history.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : journal.history.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có bản ghi nhật ký nào.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    itemCount: journal.history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = journal.history[index];
                      return _buildJournalCard(item);
                    },
                  ),
      ),
    );
  }

  Widget _buildJournalCard(JournalEntryModel item) {
    Color riskColor = AppColors.riskGreen;
    String riskText = 'Mức Xanh (Bình ổn)';
    if (item.riskAssessment?.level == 'YELLOW') {
      riskColor = AppColors.riskYellow;
      riskText = 'Mức Vàng (Căng thẳng)';
    } else if (item.riskAssessment?.level == 'RED') {
      riskColor = AppColors.riskRed;
      riskText = 'Mức Đỏ (Nguy cơ kiệt sức)';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.journalDate,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  riskText,
                  style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(Icons.bedtime_outlined, '${item.sleepHours}h ngủ', AppColors.pillarSleep),
              const SizedBox(width: 8),
              _buildStatChip(Icons.speed, 'Stress: ${item.stressLevel}/5', AppColors.pillarMental),
            ],
          ),
          if (item.physicalSymptoms.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.physicalSymptoms.map((sym) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sym,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                );
              }).toList(),
            ),
          ],
          if (item.note != null && item.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '“${item.note}”',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
