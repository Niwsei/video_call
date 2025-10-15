import 'package:stream_video_flutter/stream_video_flutter.dart';

class TutorialUser {
  const TutorialUser({required this.user, this.token});

  final User user;
  final String? token;

  // TODO: ใส่ Stream User Token จริงของ user1 ที่นี่
  // หมายเหตุ: user.id ต้องตรงกับ user_id ใน token เสมอ
  factory TutorialUser.user1() => TutorialUser(
        user: User.regular(
          userId: '68da5610e8994916f01364b8',
          name: 'ຮືວ່າງ ວ່າງ',
          image:
              'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=600',
        ),
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNjhkYTU2MTBlODk5NDkxNmYwMTM2NGI4IiwidmFsaWRpdHlfaW5fc2Vjb25kcyI6NzIwMCwiaWF0IjoxNzYwNDk0NzMwLCJleHAiOjE3NjA1MDE5MzB9.4yieYU-A6upanMzauFqI6D_LguxrvJL-FenmDrH41wM', // ใส่ STREAM USER TOKEN ของ userId นี้
      );

  // TODO: ใส่ Stream User Token จริงของ user2 ที่นี่
  factory TutorialUser.user2() => TutorialUser(
        user: User.regular(
          userId: '68ad1babd03c44ef943bb6bb',
          name: 'tangiro kamado',
          image:
              'https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg?auto=compress&cs=tinysrgb&w=600',
        ),
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNjhhZDFiYWJkMDNjNDRlZjk0M2JiNmJiIiwidmFsaWRpdHlfaW5fc2Vjb25kcyI6NzIwMCwiaWF0IjoxNzYwNDk2NzYxLCJleHAiOjE3NjA1MDM5NjF9.QKpDcVGNMWo2qaXub5iRpmejHCJO62F9m9c19LwEIqU',
      );


  static List<TutorialUser> get users => [
        TutorialUser.user1(),
        TutorialUser.user2(),
      ];
}
