import 'package:stream_video_flutter/stream_video_flutter.dart';

class TutorialUser {
  const TutorialUser({required this.user, required this.token});

  final User user;
  final String? token;

  factory TutorialUser.user1() => TutorialUser(
    user: User.regular(
      userId: 'niwner',
      name: 'niwner',
      image:
          'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    token:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibml3bmVyIiwidmFsaWRpdHlfaW5fc2Vjb25kcyI6MzYwMCwiaWF0IjoxNzU4NjE0ODg1LCJleHAiOjE3NTg2MTg0ODV9.Df7u9gUns1qiiCenWt4_00mcGY-KOcg4NnkPZbpnfaE',
  );

  factory TutorialUser.user2() => TutorialUser(
    user: User.regular(
      userId: 'sou',
      name: 'sou',
      image:
          'https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    token:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoic291IiwiZXhwIjoxNzU4MjU5NTQ3fQ.7O8plqlcDaXkJGEUqbMeQy7lUdH-QqsKL3Wh8xKHxvA',
  );

  factory TutorialUser.user3() => TutorialUser(
    user: User.regular(
      userId: 'jacky',
      name: 'jacky',
      image:
          'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    token:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiamFja3kiLCJ2YWxpZGl0eV9pbl9zZWNvbmRzIjozNjAwLCJpYXQiOjE3NTg2MTQ5MDYsImV4cCI6MTc1ODYxODUwNn0.9agbfYj6hSvBxkihLVsZN2JSsErghMmCAIsqZHliPg8',
  );

  static List<TutorialUser> get users => [
    TutorialUser.user1(),
    TutorialUser.user2(),
    TutorialUser.user3(),
  ];
}
