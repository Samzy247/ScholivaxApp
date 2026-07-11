class UserSession {
  final String token;
  final String userType; // admin | teacher | student | parent
  final int userId;
  final String? name;
  final String schoolName;
  final String subdomain;
  // Parent-only — ignored for every other role. True right after a login
  // that matched the fixed default password ('parent123'), until they set
  // their own via SetNewPasswordScreen.
  final bool mustChangePassword;

  UserSession({
    required this.token,
    required this.userType,
    required this.userId,
    required this.name,
    required this.schoolName,
    required this.subdomain,
    this.mustChangePassword = false,
  });

  UserSession copyWith({bool? mustChangePassword}) => UserSession(
        token: token,
        userType: userType,
        userId: userId,
        name: name,
        schoolName: schoolName,
        subdomain: subdomain,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );

  String get baseUrl => 'https://$subdomain.scholivax.top';

  /// The real website's per-role dashboard page — where its actual
  /// analytics/charts live. Note this is NOT the same as [baseUrl] alone:
  /// the bare domain serves the public marketing homepage regardless of
  /// login state, so Home must load this specific path to show analytics.
  String get dashboardPath {
    switch (userType) {
      case 'admin':
        return '/admin/dashboard';
      case 'teacher':
        return '/teacher/dashboard';
      case 'parent':
        return '/parents/dashboard';
      case 'student':
      default:
        return '/student/dashboard';
    }
  }

  Map<String, String> toPrefsMap() => {
        'token': token,
        'userType': userType,
        'userId': userId.toString(),
        'name': name ?? '',
        'schoolName': schoolName,
        'subdomain': subdomain,
      };

  factory UserSession.fromPrefsMap(Map<String, String> map) => UserSession(
        token: map['token']!,
        userType: map['userType']!,
        userId: int.tryParse(map['userId'] ?? '') ?? 0,
        name: map['name'],
        schoolName: map['schoolName'] ?? '',
        subdomain: map['subdomain']!,
      );
}
