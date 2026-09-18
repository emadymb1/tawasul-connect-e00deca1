/// Which portal the signed-in person lands in. Derived from their Gibbon role
/// category and role name — the server still enforces every permission.
enum Portal { student, parent, teacher, admin }

class SessionUser {
  SessionUser({
    required this.personId,
    required this.username,
    required this.preferredName,
    required this.surname,
    required this.roleName,
    required this.roleCategory,
    this.title,
    this.email,
    this.imageUrl,
    this.scopes = const [],
    this.schoolYearId,
  });

  final String personId;
  final String username;
  final String preferredName;
  final String surname;
  final String roleName;
  final String roleCategory;
  final String? title;
  final String? email;
  final String? imageUrl;
  final List<String> scopes;
  final String? schoolYearId;

  String get displayName {
    final full = '${title ?? ''} $preferredName $surname'.trim();
    return full.isEmpty ? username : full.replaceAll(RegExp(r'\s+'), ' ');
  }

  String get initials {
    final parts = [preferredName, surname]
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.trim().substring(0, 1))
        .toList();
    return parts.isEmpty ? '?' : parts.take(2).join();
  }

  bool can(String scope) =>
      scopes.isEmpty || scopes.contains('*') || scopes.contains(scope);

  Portal get portal {
    final role = roleName.toLowerCase();
    final category = roleCategory.toLowerCase();
    if (category == 'student') return Portal.student;
    if (category == 'parent') return Portal.parent;
    if (role.contains('admin')) return Portal.admin;
    return Portal.teacher;
  }

  static SessionUser fromJson(Map<String, dynamic> json) {
    // /auth/me may nest the person under `user` or `person`.
    final map = (json['user'] ?? json['person'] ?? json) as Map;
    String str(List<String> keys, [String fallback = '']) {
      for (final key in keys) {
        final value = map[key];
        if (value != null && '$value'.isNotEmpty) return '$value';
      }
      return fallback;
    }

    final rawScopes = json['scopes'] ?? map['scopes'];
    return SessionUser(
      personId: str(['gibbonPersonID', 'personID', 'id']),
      username: str(['username', 'email']),
      preferredName: str(['preferredName', 'firstName']),
      surname: str(['surname', 'lastName']),
      roleName: str(['role', 'roleName', 'primaryRole'], 'Teacher'),
      roleCategory: str(['roleCategory', 'category'], 'Staff'),
      title: map['title']?.toString(),
      email: map['email']?.toString(),
      imageUrl: (map['image_240'] ?? map['image'])?.toString(),
      scopes: rawScopes is List
          ? rawScopes.map((e) => '$e').toList()
          : (rawScopes is String
              ? rawScopes.split(',').map((e) => e.trim()).toList()
              : const []),
      schoolYearId: (json['gibbonSchoolYearID'] ??
              map['gibbonSchoolYearID'])
          ?.toString(),
    );
  }
}
