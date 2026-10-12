import 'wellbeing_score.dart';

class AssessmentOption {
  final String text;
  final double score; // 0 to 100

  const AssessmentOption({required this.text, required this.score});
}

class AssessmentQuestion {
  final String id;
  final PillarType pillar;
  final String question;
  final String contextHint;
  final List<AssessmentOption> options;

  const AssessmentQuestion({
    required this.id,
    required this.pillar,
    required this.question,
    required this.contextHint,
    required this.options,
  });

  static List<AssessmentQuestion> get defaultQuestions => [
        // SLEEP (Trọng điểm của SV làm ca LG Display)
        const AssessmentQuestion(
          id: 's1',
          pillar: PillarType.sleep,
          question: 'Sau khi ngừng làm ca kíp tại LG Display, giấc ngủ của bạn hiện nay thế nào?',
          contextHint: 'Nhiều bạn bị lệch nhịp sinh học do đổi ca liên tục',
          options: [
            AssessmentOption(text: 'Rất khó ngủ, thức khuya 1-2h sáng và ngủ chập chờn', score: 30),
            AssessmentOption(text: 'Khó ngủ vào giờ cố định, thường mệt mỏi khi thức dậy', score: 50),
            AssessmentOption(text: 'Mất 1-2 ngày cuối tuần để ngủ bù, chưa ổn định', score: 70),
            AssessmentOption(text: 'Đã lấy lại nhịp ngủ bình thường (7-8 tiếng/ngày)', score: 95),
          ],
        ),
        const AssessmentQuestion(
          id: 's2',
          pillar: PillarType.sleep,
          question: 'Bạn có cần dùng caffeine/nước tăng lực để duy trì sự tỉnh táo khi học lại?',
          contextHint: 'Thói quen duy trì ca làm việc nhà máy',
          options: [
            AssessmentOption(text: 'Rất thường xuyên (2-3 cữ/ngày mới tỉnh táo được)', score: 35),
            AssessmentOption(text: 'Uống 1 cữ mỗi sáng để tránh buồn ngủ khi lên lớp', score: 65),
            AssessmentOption(text: 'Thỉnh thoảng mới uống khi ôn thi hoặc làm bài tập', score: 85),
            AssessmentOption(text: 'Hầu như không cần, cơ thể tỉnh táo tự nhiên', score: 100),
          ],
        ),

        // PHYSICAL (Đứng phòng sạch, đau mỏi cột sống)
        const AssessmentQuestion(
          id: 'p1',
          pillar: PillarType.physical,
          question: 'Bạn có còn gặp các triệu chứng đau mỏi cơ xương khớp sau 3 tháng đứng line/phòng sạch?',
          contextHint: 'Áp lực vận động tĩnh kéo dài trong bộ đồ Cleanroom',
          options: [
            AssessmentOption(text: 'Đau mỏi vai gáy và thắt lưng thường xuyên, chân nặng nề', score: 35),
            AssessmentOption(text: 'Mỏi ê ẩm sau mỗi buổi học hoặc ngồi lâu một chỗ', score: 55),
            AssessmentOption(text: 'Chỉ hơi căng cơ nhẹ, nghỉ ngơi là đỡ', score: 75),
            AssessmentOption(text: 'Cơ thể nhẹ nhõm, không còn cảm giác đau mỏi', score: 95),
          ],
        ),
        const AssessmentQuestion(
          id: 'p2',
          pillar: PillarType.physical,
          question: 'Mức độ vận động thể chất/thể thao của bạn sau khi kết thúc thực tập?',
          contextHint: 'Hồi phục độ dẻo dai sau kỳ thực tập căng thẳng',
          options: [
            AssessmentOption(text: 'Hầu như không vận động, cả ngày chỉ nằm hoặc ngồi phòng trọ', score: 30),
            AssessmentOption(text: 'Chỉ đi bộ nhẹ khi đi học, chưa tập thể dục', score: 55),
            AssessmentOption(text: 'Có tập nhẹ 1-2 buổi/tuần (chạy bộ, cầu lông...)', score: 75),
            AssessmentOption(text: 'Duy trì tập luyện đều đặn từ 3 buổi/tuần trở lên', score: 95),
          ],
        ),

        // MENTAL (Stress, hụt hẫng khi quay về trường)
        const AssessmentQuestion(
          id: 'm1',
          pillar: PillarType.mental,
          question: 'Khi chuyển từ guồng làm việc LG Display về lại môi trường giảng đường, bạn cảm thấy thế nào?',
          contextHint: 'Hiện tượng "Post-internship Blues" - Hụt hẫng sau thực tập',
          options: [
            AssessmentOption(text: 'Cảm giác trống rỗng, mất động lực học và khó tập trung', score: 35),
            AssessmentOption(text: 'Thấy chênh vênh, chưa quen lại với bài vở và thi cử', score: 55),
            AssessmentOption(text: 'Hơi lười lúc đầu nhưng đang dần bắt nhịp lại được', score: 75),
            AssessmentOption(text: 'Cảm thấy tràn đầy năng lượng và hào hứng với kỳ học mới', score: 95),
          ],
        ),
        const AssessmentQuestion(
          id: 'm2',
          pillar: PillarType.mental,
          question: 'Bạn có cảm thấy lo lắng khi nghĩ về áp lực thi cử và đồ án sắp tới?',
          contextHint: 'Dồn nén kiến thức sau 3 tháng tạm ngưng học thuật',
          options: [
            AssessmentOption(text: 'Rất lo âu, cảm giác bị tụt hậu so với các bạn không đi thực tập', score: 40),
            AssessmentOption(text: 'Khá căng thẳng vì lượng kiến thức cần bù đắp nhiều', score: 60),
            AssessmentOption(text: 'Có chút áp lực nhưng tự tin sắp xếp được', score: 80),
            AssessmentOption(text: 'Hoàn toàn tự tin và có kế hoạch học tập rõ ràng', score: 95),
          ],
        ),

        // SOCIAL (Tái kết nối bạn bè)
        const AssessmentQuestion(
          id: 'so1',
          pillar: PillarType.social,
          question: 'Mối quan hệ và sự kết nối của bạn với bạn bè sau khi về trường ra sao?',
          contextHint: 'Rời xa nhóm bạn cùng ca kíp để về lớp',
          options: [
            AssessmentOption(text: 'Cảm thấy xa cách, khó tìm tiếng nói chung với bạn ở trường', score: 40),
            AssessmentOption(text: 'Nhớ môi trường công ty, ít nói chuyện hơn trước', score: 60),
            AssessmentOption(text: 'Thỉnh thoảng gặp gỡ nhóm bạn thân và bạn cùng đi thực tập', score: 80),
            AssessmentOption(text: 'Kết nối rất tốt, thoải mái chia sẻ trải nghiệm thực tập', score: 95),
          ],
        ),

        // CAREER (Định hướng sau thực tập)
        const AssessmentQuestion(
          id: 'c1',
          pillar: PillarType.career,
          question: 'Sau 3 tháng trải nghiệm thực tế tại LG Display, bạn nhìn nhận thế nào về ngành nghề?',
          contextHint: 'Xác thực độ phù hợp của bản thân với ngành sản xuất công nghệ cao',
          options: [
            AssessmentOption(text: 'Rất bối rối, nhận thấy không phù hợp và muốn đổi hướng', score: 45),
            AssessmentOption(text: 'Chưa chắc chắn, còn nhiều băn khoăn về môi trường nhà máy', score: 60),
            AssessmentOption(text: 'Khá phù hợp, nhưng cần trau dồi thêm nhiều kỹ năng còn thiếu', score: 80),
            AssessmentOption(text: 'Rất rõ ràng về mục tiêu và tiếp tục theo đuổi ngành này', score: 95),
          ],
        ),
      ];
}
