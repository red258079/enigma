class HandbookArticle {
  final String id;
  final String title;
  final String category; // sleep, physical, mental, social, career
  final String categoryName;
  final String summary;
  final String content;
  final List<String> keyTakeaways;
  final int readTimeMinutes;

  HandbookArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryName,
    required this.summary,
    required this.content,
    required this.keyTakeaways,
    this.readTimeMinutes = 3,
  });

  static List<HandbookArticle> get initialArticles => [
    HandbookArticle(
      id: 'h6-esd-shoes-care',
      title: 'Giảm đau chân khi mang giày bảo hộ ESD & đứng ca dài',
      category: 'physical',
      categoryName: 'Thể chất & Cơ khớp',
      summary: 'Kinh nghiệm chống đau nhức gan bàn chân, gót chân khi mang giày chống tĩnh điện (ESD) 8–12 tiếng/ngày.',
      content: '''
Tại nhà máy như LG Display, giày bảo hộ chống tĩnh điện (ESD) là bắt buộc. Do đế giày cứng và phải đứng thao tác liên tục trên sàn epoxy, hầu hết sinh viên trong 2 tuần đầu đều bị đau nhức dữ dội gan bàn chân và gót chân.

1. Lót giày y tế / Silicon:
Mua ngay miếng lót giày giảm áp lực (loại có đệm nâng vòm chân hoặc gel silicon). Đây là "cứu tinh" hiệu quả nhất, giảm tới 60% phản lực từ sàn cứng.

2. Chọn tất (vớ) cotton dày:
Nên mang tất thể thao dệt dày hoặc mang 2 lớp tất mỏng. Điều này vừa giúp thấm mồ hôi, vừa chống phồng rộp các ngón chân khi cọ xát với mũi giày thép.

3. Kỹ thuật phục hồi sau ca làm:
- Ngâm chân nước ấm pha muối gừng khoảng 15 phút trước khi đi ngủ.
- Dùng một quả bóng tennis hoặc chai nước đông đá lăn dưới lòng bàn chân 5 phút mỗi bên để xoa bóp cân gan chân.
- Khi ngủ, kê gối cao dưới bắp chân giúp máu hồi lưu về tim tốt hơn, giảm phù nề chân rõ rệt.
''',
      keyTakeaways: [
        'Trang bị ngay miếng lót giày đệm silicon chuyên dụng',
        'Kê cao chân khi ngủ để giảm sưng phù và ứ máu',
        'Lăn bóng tennis dưới lòng bàn chân 5 phút mỗi tối',
        'Chọn tất cotton dày để giảm ma sát mũi giày'
      ],
      readTimeMinutes: 3,
    ),
    HandbookArticle(
      id: 'h2-sleep-shift',
      title: 'Cân bằng nhịp sinh học khi đổi ca ngày sang ca đêm',
      category: 'sleep',
      categoryName: 'Giấc ngủ & Ca kíp',
      summary: 'Làm thế nào để ngủ sâu và không bị kiệt sức khi chuyển đổi luân phiên giữa ca ngày (08h-20h) và ca đêm (20h-08h).',
      content: '''
Lệch ca làm việc là nguyên nhân hàng đầu khiến sinh viên mất ngủ và kiệt sức trong kỳ thực tập sản xuất.

1. Quy tắc phòng ngủ ca ngày:
Khi làm ca đêm về lúc 08h sáng, ánh nắng mặt trời sẽ ức chế tiết melatonin khiến bạn khó ngủ.
- Sử dụng rèm chắn sáng 100% hoặc đeo bịt mắt ngủ.
- Đeo nút tai chống ồn nếu ở ký túc xá đông người.
- Bật quạt hoặc điều hòa giữ nhiệt độ phòng mát mẻ (khoảng 24-26°C).

2. Ăn uống khi làm ca đêm:
- Không ăn bữa quá no vào lúc 02:00 - 04:00 sáng vì hệ tiêu hóa đang chậm lại. Nên ăn nhẹ bằng chuối, yến mạch hoặc bánh quy nguyên cám.
- Hạn chế cà phê hoặc nước tăng lực sau 03:00 sáng để khi về phòng lúc 08:30 có thể ngủ được ngay.

3. Kỹ thuật Power Nap:
Nếu quá mệt trong giờ giải lao giữa ca đêm, hãy chợp mắt nhanh 15–20 phút. Tránh ngủ quá 30 phút vì sẽ rơi vào giấc ngủ sâu, khi tỉnh dậy sẽ bị choáng váng.
''',
      keyTakeaways: [
        'Dùng rèm cản sáng và bịt mắt khi ngủ ban ngày',
        'Cắt cà phê sau 03h sáng để tránh mất ngủ lúc về phòng',
        'Ngủ chợp mắt 15-20 phút trong giờ nghỉ giữa ca',
        'Uống đủ nước ấm, tránh nước đá lạnh trong ca đêm'
      ],
      readTimeMinutes: 4,
    ),
    HandbookArticle(
      id: 'h3-stress-relief',
      title: 'Kỹ thuật thở Box Breathing 4-4-4-4 giảm căng thẳng tức thì',
      category: 'mental',
      categoryName: 'Tinh thần & Tâm lý',
      summary: 'Phương pháp kiểm soát nhịp tim và cortisol khi gặp sự cố dây chuyền hoặc áp lực công việc đột ngột.',
      content: '''
Khi bị Trưởng ca nhắc nhở hoặc dây chuyền gặp sự cố phát sinh lỗi, cơ thể bạn sẽ phản ứng chiến-hay-biến (Fight-or-Flight), tim đập nhanh và hoảng loạn.

Kỹ thuật Box Breathing (Thở hình vuông):
1. Hít vào chậm qua mũi trong 4 giây, cảm nhận bụng phình lên.
2. Giữ hơi thở trong lồng ngực trong 4 giây.
3. Thở ra từ từ qua miệng trong 4 giây, xẹp bụng xuống.
4. Giữ phổi trống trong 4 giây.

Lặp lại chu kỳ này 4 lần liên tiếp (chỉ mất đúng 1 phút). Hệ thần kinh phó giao cảm sẽ được kích hoạt ngay lập tức, đưa nhịp tim và sóng não về trạng thái bình tĩnh, sáng suốt.
''',
      keyTakeaways: [
        'Hít 4s - Nín thở 4s - Thở ra 4s - Nín thở 4s',
        'Thực hiện trong 1 phút bất cứ khi nào thấy tim đập nhanh',
        'Giúp ổn định hệ thần kinh phó giao cảm và giảm cortisol'
      ],
      readTimeMinutes: 2,
    ),
    HandbookArticle(
      id: 'h1-5s-lgd',
      title: 'Quy tắc 5S và Kỷ luật an toàn lao động nhà máy',
      category: 'career',
      categoryName: 'Nghề nghiệp & Nhà máy',
      summary: 'Hiểu đúng về Seiri, Seiton, Seiso, Seiketsu, Shitsuke để không bị đánh giá lỗi trong tháng đầu.',
      content: '''
Quy tắc 5S là tiêu chuẩn sống còn tại các nhà máy công nghệ cao:
- Sàng lọc (Seiri): Chỉ giữ lại linh kiện, công cụ cần thiết cho ca làm.
- Sắp xếp (Seiton): Dụng cụ để đúng vị trí vạch kẻ, "dễ tìm, dễ thấy, dễ lấy, dễ trả lại".
- Sạch sẽ (Seiso): Vệ sinh buồng phòng sạch (Cleanroom), không để bụi bẩn bám dính sensor.
- Săn sóc (Seiketsu): Duy trì 3S trên thành thói quen kiểm tra trước khi bàn giao ca.
- Sẵn sàng (Shitsuke): Tuân thủ nghiêm ngặt giờ giấc, trang phục bảo hộ và quẹt thẻ.
''',
      keyTakeaways: [
        'Tuyệt đối không mang đồ kim loại, điện thoại vào phòng sạch không phép',
        'Giao ca đúng giờ và ghi chép nhật ký bàn giao đầy đủ'
      ],
      readTimeMinutes: 3,
    ),
    HandbookArticle(
      id: 'h7-roommate-conflict',
      title: 'Ứng xử khi bất đồng với bạn cùng phòng KTX',
      category: 'social',
      categoryName: 'Xã hội & Giao tiếp',
      summary: 'Cách thiết lập thỏa thuận chung về giờ ngủ, dọn dẹp và thủ tục xin đổi phòng nếu không hợp.',
      content: '''
Ở trọ hoặc ký túc xá khi làm lệch ca (người làm ca ngày, người làm ca đêm) rất dễ phát sinh xung đột về tiếng ồn, ánh sáng điện thoại và vệ sinh chung.

1. Thiết lập "Hiệp ước im lặng":
Ngay tuần đầu tiên, hãy ngồi lại quy định khung giờ yên tĩnh (ví dụ: 09h-17h cho người làm ca đêm ngủ, và 22h-06h cho người làm ca ngày). Khi về phòng trong giờ ngủ của bạn, dùng đèn pin điện thoại hoặc đèn bàn nhỏ, không bật đèn trần.

2. Phân chia rác và dọn dẹp:
Lập lịch trực nhật xoay vòng. Khi có điều không hài lòng, góp ý thẳng thắn nhưng nhẹ nhàng, tránh im lặng rồi bức xúc tích tụ.
''',
      keyTakeaways: [
        'Thống nhất giờ yên tĩnh cho ca ngủ của nhau',
        'Đeo tai nghe khi xem phim, nghe nhạc trong phòng trọ',
        'Nếu mâu thuẫn kéo dài ảnh hưởng sức khỏe, chủ động báo quản lý KTX'
      ],
      readTimeMinutes: 3,
    ),
    HandbookArticle(
      id: 'h8-rights-allowance',
      title: 'Quyền lợi, phụ cấp ca đêm và an toàn thực tập sinh',
      category: 'career',
      categoryName: 'Nghề nghiệp & Nhà máy',
      summary: 'Nắm vững quyền lợi về bữa ăn ca, xe đưa đón và phụ cấp theo quy định để yên tâm làm việc.',
      content: '''
Sinh viên thực tập thường e ngại không dám hỏi về quyền lợi của mình:
- Bữa ăn giữa ca: Nhà máy luôn cung cấp suất ăn miễn phí đảm bảo calo.
- Xe bus đưa đón: Tra cứu lịch trình tuyến xe bus nội bộ để không bị trễ ca.
- Khi ốm đau: Được nghỉ theo chế độ y tế của nhà máy và nhà trường, cần báo cho cả Quản lý ca và Giảng viên phụ trách.
''',
      keyTakeaways: [
        'Lưu số điện thoại y tế nhà máy và xe bus nội bộ',
        'Nắm rõ cách chấm công và bảng kê phụ cấp hàng tháng'
      ],
      readTimeMinutes: 3,
    ),
  ];
}
