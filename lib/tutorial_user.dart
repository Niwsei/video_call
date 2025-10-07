import 'package:stream_video_flutter/stream_video_flutter.dart';

class TutorialUser {
  const TutorialUser({required this.user, this.token});

  final User user;
  final String? token;

  // TODO: ใส่ Stream User Token จริงของ user1 ที่นี่
  // หมายเหตุ: user.id ต้องตรงกับ user_id ใน token เสมอ
  factory TutorialUser.user1() => TutorialUser(
        user: User.regular(
          userId: '6721f3f8cd5644f9dc80f4f9',
          name: 'ev manager test',
          image:
              'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=600',
        ),
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNjcyMWYzZjhjZDU2NDRmOWRjODBmNGY5IiwidmFsaWRpdHlfaW5fc2Vjb25kcyI6MzYwMCwiaWF0IjoxNzU5ODA2MTA0LCJleHAiOjE3NTk4MDk3MDR9.TDderLmOXPviB2k_EoKDKNmj23QPhg-V1H0UPnaroY4', // ใส่ STREAM USER TOKEN ของ userId นี้
      );

  // TODO: ใส่ Stream User Token จริงของ user2 ที่นี่
  factory TutorialUser.user2() => TutorialUser(
        user: User.regular(
          userId: '68a2eccfbffc43ed49cdf13f',
          name: ' Dee admin1 Express',
          image:
              'https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg?auto=compress&cs=tinysrgb&w=600',
        ),
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNjhhMmVjY2ZiZmZjNDNlZDQ5Y2RmMTNmIiwidmFsaWRpdHlfaW5fc2Vjb25kcyI6MzYwMCwiaWF0IjoxNzU5ODA1OTIxLCJleHAiOjE3NTk4MDk1MjF9.R_yrnbFZ-bxMHuuI8liuuxKR3nsbT8gPc_T7peiepJE',
      );


  static List<TutorialUser> get users => [
        TutorialUser.user1(),
        TutorialUser.user2(),
      ];
}
