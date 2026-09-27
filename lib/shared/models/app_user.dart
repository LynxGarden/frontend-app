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
    this.authUserId,
    this.firstName,
    this.lastName,
    this.email,
    this.avatarKind,
    this.avatarValue,
    this.dateOfBirth,
    this.gender,
    this.onboardingComplete = false,
  });

  final String personId;
  final String tenantId;
  final Set<AppRole> roles;
  final String locale;

  /// The Supabase auth user this domain record belongs to. Lets the UI detect an
  /// account switch (a stale cached user from a previous session) before the new
  /// record loads, so the wrong role's shell never flashes.
  final String? authUserId;
  final String? firstName;
  final String? lastName;
  final String? email;

  /// Avatar: `null` (→ initials) · `'dicebear'` (config JSON in [avatarValue]) ·
  /// `'photo'` (storage path in [avatarValue]).
  final String? avatarKind;
  final String? avatarValue;
  final DateTime? dateOfBirth;

  /// Optional self-selected gender ('male' / 'female'); biases avatar generation.
  final String? gender;
  final bool onboardingComplete;

  /// Display name, falling back to email then a dash.
  String get fullName {
    final name = [firstName, lastName]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(' ')
        .trim();
    if (name.isNotEmpty) return name;
    return email ?? '—';
  }

  /// Up to two initials for the avatar fallback.
  String get initials {
    final f = (firstName ?? '').trim();
    final l = (lastName ?? '').trim();
    final a = f.isNotEmpty ? f[0] : '';
    final b = l.isNotEmpty ? l[0] : '';
    final combined = (a + b).toUpperCase();
    return combined.isNotEmpty ? combined : '?';
  }

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

  factory AppUser.fromJson(Map<String, dynamic> json, Set<AppRole> roles,
      {String? authUserId}) {
    final dob = json['date_of_birth'] as String?;
    return AppUser(
      personId: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      roles: roles,
      authUserId: authUserId,
      locale: (json['locale'] as String?) ?? 'en',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      avatarKind: json['avatar_kind'] as String?,
      avatarValue: json['avatar_value'] as String?,
      dateOfBirth: dob == null ? null : DateTime.tryParse(dob),
      gender: json['gender'] as String?,
      onboardingComplete: (json['onboarding_complete'] as bool?) ?? false,
    );
  }
}
