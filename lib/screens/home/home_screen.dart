import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/home_provider.dart';
import '../chat/ai_chat_screen.dart';
import '../checkin/checkin_gacha_screen.dart';
import '../handbook/handbook_screen.dart';
import '../journal/journal_screen.dart';
import '../tasks/tasks_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final home = Provider.of<HomeProvider>(context);
    final checkin = Provider.of<CheckinProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await checkin.fetchTodayStatus();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Header Profile & Streak
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                          ? Text(
                              (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Sinh viên Enigma',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${user?.companyName ?? "LG Display"} • ${user?.phaseDisplay ?? "Chặng 2"}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Streak Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.streakFire.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.streakFire.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '${checkin.status?.currentStreak ?? home.currentStreak} ngày',
                            style: const TextStyle(
                              color: AppColors.streakFire,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Daily Check-in & Gacha Banner
                _buildCheckinCard(context, checkin),
                const SizedBox(height: 24),

                // 3. 5 Pillars Health Radar / Progress Card
                _buildPillarsCard(home),
                const SizedBox(height: 24),

                // 4. Quick Action Grid
                const Text(
                  'Phím tắt nhanh',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    _buildActionCard(
                      icon: Icons.edit_note_outlined,
                      color: AppColors.pillarMental,
                      title: 'Nhật ký sinh hoạt',
                      subtitle: 'Ngủ, stress & đau chân ESD',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const JournalScreen()),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.checklist_rtl_outlined,
                      color: AppColors.pillarCareer,
                      title: 'Nhiệm vụ 3 chặng',
                      subtitle: '5S, an toàn & thích nghi',
                      onTap: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(2);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TasksScreen()),
                          );
                        }
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.menu_book_outlined,
                      color: AppColors.pillarPhysical,
                      title: 'Cẩm nang thực tế',
                      subtitle: 'Kinh nghiệm cựu sinh viên',
                      onTap: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(3);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HandbookScreen()),
                          );
                        }
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.smart_toy_outlined,
                      color: AppColors.primary,
                      title: 'Hỏi Trợ lý AI',
                      subtitle: 'Giải đáp RAG tức thì',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiChatScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Daily Advice / Quote
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: AppColors.pillarCareer, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Lời khuyên thích nghi hôm nay',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.pillarCareer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        home.dailyQuote,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckinCard(BuildContext context, CheckinProvider checkin) {
    final hasCheckedIn = checkin.status?.hasCheckedIn ?? false;
    final gachaMsg = checkin.lastGachaMessage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasCheckedIn
              ? [const Color(0xFF132A24), const Color(0xFF0F1E28)]
              : [const Color(0xFF152840), const Color(0xFF1E1E38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasCheckedIn ? AppColors.secondary.withOpacity(0.4) : AppColors.primary.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (hasCheckedIn ? AppColors.secondary : AppColors.primary).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasCheckedIn ? Icons.check_circle_outline : Icons.card_giftcard,
                      color: hasCheckedIn ? AppColors.secondary : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    hasCheckedIn ? 'Đã điểm danh hôm nay ✨' : 'Điểm danh cảm xúc & Rút Gacha',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (hasCheckedIn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Hoàn thành',
                    style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasCheckedIn && gachaMsg != null)
            Text(
              gachaMsg,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primaryLight,
                height: 1.4,
              ),
            )
          else ...[
            const Text(
              'Ghi nhận tâm trạng trước ca làm để nhận một thông điệp tiếp thêm động lực từ cựu sinh viên.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckinGachaScreen()),
                  );
                },
                icon: const Icon(Icons.casino_outlined, size: 18),
                label: const Text('Điểm danh & Quay Gacha ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPillarsCard(HomeProvider home) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 Trụ cột Thích nghi & Sức khỏe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Chỉ số tuần',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPillarBar('Giấc ngủ (Ca ngày/đêm)', home.sleepScore, AppColors.pillarSleep, Icons.bedtime_outlined),
          const SizedBox(height: 10),
          _buildPillarBar('Thể chất & Cơ khớp (Giày ESD)', home.physicalScore, AppColors.pillarPhysical, Icons.fitness_center_outlined),
          const SizedBox(height: 10),
          _buildPillarBar('Tinh thần & Giảm stress', home.mentalScore, AppColors.pillarMental, Icons.self_improvement_outlined),
          const SizedBox(height: 10),
          _buildPillarBar('Hòa nhập KTX & Giao tiếp', home.socialScore, AppColors.pillarSocial, Icons.people_outline),
          const SizedBox(height: 10),
          _buildPillarBar('Kỷ luật 5S & Nghề nghiệp', home.careerScore, AppColors.pillarCareer, Icons.work_outline),
        ],
      ),
    );
  }

  Widget _buildPillarBar(String name, int score, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
              ],
            ),
            Text(
              '$score%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
