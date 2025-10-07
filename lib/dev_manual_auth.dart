// Dev-only manual auth override for quick 1–1 testing without backend.
// How to use:
// 1) Paste real values below for user A and B (apiKey, userId, name, token)
// 2) Run app with:
//    flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=A
//    flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=B

class ManualAuthUser {
  final String apiKey;
  final String userId;
  final String name;
  final String token;

  const ManualAuthUser({
    required this.apiKey,
    required this.userId,
    required this.name,
    required this.token,
  });
}

class ManualAuth {
  static const bool enabled = bool.fromEnvironment('MANUAL_AUTH', defaultValue: false);
  static const String selected = String.fromEnvironment('MANUAL_AUTH_USER', defaultValue: 'A');

  // TODO: Paste your real credentials here for quick testing.
  // Note: Never commit production secrets. apiKey is public; token is per-user.
  static const ManualAuthUser userA = ManualAuthUser(
    apiKey: 'r9mn4fsbzhub',
    userId: '68da5610e8994916f01364b8',
    name: 'ຮືວ່າງ ວ່າງ',
    token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNjhkYTU2MTBlODk5NDkxNmYwMTM2NGI4IiwidmFsaWRpdHlfaW5fc2Vjb25kcyI6NzIwMCwiaWF0IjoxNzU5ODE5MTMyLCJleHAiOjE3NTk4MjYzMzJ9.nUk_CXHHmp6HICwoPyHm0Ag2jQqmcdVMPuMBmXOK0-0',
  );

  static const ManualAuthUser userB = ManualAuthUser(
    apiKey: 'r9mn4fsbzhub',
    userId: '68ad1babd03c44ef943bb6bb',
    name: 'tangiro kamado',
    token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNjhhZDFiYWJkMDNjNDRlZjk0M2JiNmJiIiwidmFsaWRpdHlfaW5fc2Vjb25kcyI6NzIwMCwiaWF0IjoxNzU5ODE5MTc2LCJleHAiOjE3NTk4MjYzNzZ9.vu4ggDIRUAt75icLZiSmnty73SsHtA0ED22kHBEFDf4',
  );

  static ManualAuthUser current() =>
      (selected.toUpperCase() == 'B') ? userB : userA;
}

