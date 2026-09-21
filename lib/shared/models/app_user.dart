/// The signed-in user's domain identity: their `person` row (tenant + roles).
///
/// This is NOT the raw auth user — it's the tenant-scoped record the whole app
/// keys off. A user with a valid auth session but no linked `person` row is
/// "not linked yet" (see currentUserProvider returning null).
enum AppRole { owner, coach, physio, client }

AppRole? appRoleFromString(String value) {
  switch (value) {
    case 'owner':
      return AppRole.owner;
    case 'coach':
      return AppRole.coach;
    case 'physio':
      return AppRole.physio;
    case 'client':
      return AppRole.client;
    default:
      return null;
  }
}

class AppUser {
  const AppUser({
    required this.personId,
    required this.tenantId,
    required this.roles,
    required this.locale,
    this.firstName,
    this.lastName,
    this.email,
  });

  final String personId;
  final String tenantId;
  final Set<AppRole> roles;
  final String locale;
  final String? firstName;
  final String? lastName;
  final String? email;

  /// Staff = owner / coach / physio. Drives which shell the user sees.
  bool get isStaff =>
      roles.contains(AppRole.owner) ||
      roles.contains(AppRole.coach) ||
      roles.contains(AppRole.physio);

  /// Highest-privilege role, used for display / defaulting.
  AppRole get primaryRole {
    if (roles.contains(AppRole.owner)) return AppRole.owner;
    if (roles.contains(AppRole.coach)) return AppRole.coach;
    if (roles.contains(AppRole.physio)) return AppRole.physio;
    return AppRole.client;
  }

  factory AppUser.fromJson(Map<String, dynamic> json, Set<AppRole> roles) {
    return AppUser(
      personId: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      roles: roles,
      locale: (json['locale'] as String?) ?? 'en',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
    );
  }
}
