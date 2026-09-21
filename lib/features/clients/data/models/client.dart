/// A client record (a `person` with the client role). May be account-less
/// (no linked login) — operated by staff on their behalf.
class Client {
  const Client({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.lifecycleStage = 'regular',
    this.locale = 'en',
    this.hasAccount = false,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String lifecycleStage;
  final String locale;
  final bool hasAccount;

  String get fullName {
    final n = '$firstName $lastName'.trim();
    return n.isEmpty ? (email ?? '—') : n;
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final i = '$f$l'.trim();
    return i.isEmpty ? '?' : i.toUpperCase();
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      lifecycleStage: (json['lifecycle_stage'] as String?) ?? 'regular',
      locale: (json['locale'] as String?) ?? 'en',
      hasAccount: json['auth_user_id'] != null,
    );
  }
}
