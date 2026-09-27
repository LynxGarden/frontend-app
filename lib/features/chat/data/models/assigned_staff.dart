import 'package:lynx_app/shared/models/app_user.dart';

/// A staff member (coach/physio) assigned to a client — a row in the client's
/// master chat list.
class AssignedStaff {
  const AssignedStaff({
    required this.staffPersonId,
    required this.role,
    this.firstName,
    this.lastName,
    this.avatarKind,
    this.avatarValue,
  });

  final String staffPersonId;
  final AppRole role;
  final String? firstName;
  final String? lastName;
  final String? avatarKind;
  final String? avatarValue;

  String get fullName {
    final name = [firstName, lastName]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(' ')
        .trim();
    return name.isNotEmpty ? name : '—';
  }

  String get initials {
    final f = (firstName ?? '').trim();
    final l = (lastName ?? '').trim();
    final combined =
        ((f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '')).toUpperCase();
    return combined.isNotEmpty ? combined : '?';
  }

  factory AssignedStaff.fromJson(Map<String, dynamic> json) => AssignedStaff(
        staffPersonId: json['staff_person_id'] as String,
        role: appRoleFromString(json['role'] as String? ?? 'coach') ??
            AppRole.coach,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        avatarKind: json['avatar_kind'] as String?,
        avatarValue: json['avatar_value'] as String?,
      );
}
