class GachaMessages {
  static const List<String> motivation = [
    "Khởi đầu nhỏ bé hôm nay sẽ tạo ra thành tựu vĩ đại ngày mai.",
    "Bạn đang làm rất tốt, hãy tiếp tục phát huy nhé!",
    "Mọi khó khăn đều là cơ hội để bạn trưởng thành hơn.",
    "Tin vào bản thân, bạn có thể làm được nhiều hơn thế.",
    "Đừng so sánh mình với ai, hãy là phiên bản tốt hơn của bạn ngày hôm qua.",
    "Thực tập không chỉ là làm việc, mà là học cách làm việc.",
    "Hãy mỉm cười, một ngày mới tràn đầy năng lượng đang chờ bạn.",
    "Một chút kiên nhẫn sẽ mang lại thành quả ngọt ngào.",
    "Đừng ngại đặt câu hỏi, đó là cách nhanh nhất để học hỏi.",
    "Bạn không cô đơn, Enigma luôn đồng hành cùng bạn."
  ];

  static const List<String> health = [
    "Đừng quên uống đủ nước hôm nay nhé!",
    "Hãy dành 5 phút hít thở sâu để giảm căng thẳng.",
    "Giấc ngủ là liều thuốc tốt nhất cho cả cơ thể và tâm trí.",
    "Hãy vươn vai và giãn cơ một chút nếu bạn ngồi quá lâu.",
    "Sức khỏe của bạn là ưu tiên hàng đầu, hãy giữ gìn nhé.",
    "Một bữa ăn ngon sẽ nạp lại năng lượng cho bạn ngay lập tức.",
    "Cố gắng ngủ trước 11h đêm để cơ thể được phục hồi tốt nhất.",
    "Đừng để công việc lấy đi sức khỏe của bạn.",
    "Hãy thử tập thể dục 15 phút mỗi ngày, bạn sẽ thấy sự khác biệt.",
    "Hôm nay bạn đã cười chưa? Nụ cười giúp xua tan mệt mỏi đấy."
  ];

  static const List<String> social = [
    "Hãy gửi một lời chào đến đồng nghiệp mới của bạn.",
    "Mở lòng và chia sẻ, bạn sẽ tìm thấy sự đồng cảm.",
    "Đừng ngại nhờ sự giúp đỡ khi cần thiết.",
    "Sự tử tế sẽ kết nối những trái tim.",
    "Hãy thử rủ ai đó cùng ăn trưa hôm nay.",
    "Một lời khen chân thành có thể làm bừng sáng ngày của ai đó.",
    "Xây dựng mối quan hệ tốt ở nơi làm việc sẽ giúp bạn rất nhiều.",
    "Lắng nghe người khác cũng là một cách học hỏi tuyệt vời.",
    "Hãy giữ liên lạc với gia đình và bạn bè, họ là hậu phương vững chắc.",
    "Đồng nghiệp không chỉ là người làm chung, họ có thể là bạn tốt."
  ];

  static const List<String> career = [
    "Mỗi sai lầm là một bài học đắt giá cho sự nghiệp của bạn.",
    "Hãy luôn tò mò và khao khát học hỏi điều mới.",
    "Chủ động trong công việc sẽ giúp bạn ghi điểm trong mắt sếp.",
    "Đừng ngại đảm nhận những thử thách mới, đó là cơ hội tỏa sáng.",
    "Thái độ làm việc quan trọng hơn cả kỹ năng.",
    "Hãy ghi chép lại những gì bạn học được mỗi ngày.",
    "Luôn giữ thái độ chuyên nghiệp, ngay cả trong những việc nhỏ nhất.",
    "Xác định rõ mục tiêu của kỳ thực tập này và hướng tới nó.",
    "Đừng ngại đề xuất ý tưởng của bạn, dù nó có vẻ điên rồ.",
    "Hãy tự hào về những gì bạn đang làm."
  ];

  static List<String> get allMessages => [
    ...motivation,
    ...health,
    ...social,
    ...career
  ];

  static String getRandomMessage() {
    final messages = allMessages;
    messages.shuffle();
    return messages.first;
  }
}
