/// Lets an in-place overlay (a guide, a sheet drawn inside a page) take the
/// next Android back before the shell's own back logic runs.
library;

typedef ShellBackHandler = bool Function();

class ShellBack {
  ShellBack._();
  static final List<ShellBackHandler> _claims = [];

  /// Registers [h]; newest claims are asked first.
  static void claim(ShellBackHandler h) {
    _claims.remove(h);
    _claims.add(h);
  }

  static void release(ShellBackHandler h) => _claims.remove(h);

  /// True if a claim consumed the press.
  static bool handle() {
    for (final h in _claims.reversed.toList()) {
      if (h()) return true;
    }
    return false;
  }
}
