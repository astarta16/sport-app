/// Pure validation helpers. They return an error *code*; the presentation
/// layer translates codes to localized messages.
class Validators {
  Validators._();

  /// Georgian mobile numbers: +995 5XX XXX XXX (9 national digits starting with 5).
  static String normalizePhone(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('00995')) digits = '+${digits.substring(2)}';
    if (digits.startsWith('995')) digits = '+$digits';
    if (!digits.startsWith('+')) digits = '+995$digits';
    return digits;
  }

  static String? phone(String? input) {
    if (input == null || input.trim().isEmpty) return 'required';
    final n = normalizePhone(input);
    if (!RegExp(r'^\+9955\d{8}$').hasMatch(n)) return 'invalidPhone';
    return null;
  }

  static String? otp(String? input) {
    if (input == null || input.isEmpty) return 'required';
    if (!RegExp(r'^\d{6}$').hasMatch(input)) return 'invalidOtp';
    return null;
  }

  static String? name(String? input) {
    final v = input?.trim() ?? '';
    if (v.isEmpty) return 'required';
    if (v.length < 2) return 'tooShort';
    if (v.length > 40) return 'tooLong';
    if (!RegExp(r"^[\p{L}\s'\-]+$", unicode: true).hasMatch(v)) return 'invalidName';
    return null;
  }

  static String? birthDate(DateTime? date, DateTime now) {
    if (date == null) return 'required';
    if (date.isAfter(now)) return 'dateInFuture';
    if (now.difference(date).inDays > 365 * 19) return 'tooOldForChild';
    if (now.difference(date).inDays < 365 * 3) return 'tooYoung';
    return null;
  }

  /// Formats +995555123456 as "+995 555 12 34 56".
  static String formatPhone(String phone) {
    final n = normalizePhone(phone);
    if (n.length != 13) return phone;
    final d = n.substring(4);
    return '+995 ${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5, 7)} ${d.substring(7)}';
  }

  /// Masks all but the last 2 digits, e.g. "+995 5** ** ** 56".
  static String maskPhone(String phone) {
    final n = normalizePhone(phone);
    if (n.length < 6) return '***';
    return '${n.substring(0, 5)}*** ** *${n.substring(n.length - 2)}';
  }
}
