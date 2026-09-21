/// Common validation helpers that can be reused across forms.
///
/// Keep these functions pure (no BuildContext / UI side effects) so they are
/// easy to test and reuse.
library;

/// Returns `true` if [email] looks like a valid email address.
///
/// Validates format only — not whether the inbox exists.
bool isValidEmailFormat(String email) {
  final value = email.trim();
  if (value.isEmpty) return false;

  final regex = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
    caseSensitive: false,
  );
  return regex.hasMatch(value);
}

/// Returns true if [password] has at least [min] characters.
bool hasMinLength(String password, {int min = 8}) =>
    password.trim().runes.length >= min;

/// Returns true if [password] contains at least one uppercase A-Z letter.
bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);

/// Returns true if [password] contains at least one lowercase a-z letter.
bool hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);

/// Returns true if [password] contains at least one special character.
bool hasSpecialCharacter(String password) =>
    RegExp(r'[^A-Za-z0-9\s]').hasMatch(password);

/// Returns true if [password] contains at least one digit 0-9.
bool hasNumber(String password) => RegExp(r'[0-9]').hasMatch(password);
