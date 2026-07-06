/// Design-system spacing and radius tokens — the single ruler for the app.
///
/// Every shared primitive and screen should reach for [NidSpace] and
/// [NidRadius] instead of freehand magic numbers so spacing and corners stay
/// on one deliberate grid (DS-02). Values are plain doubles, so no Flutter
/// import is required.
library;

/// The one spacing scale. Widening, 4-based steps.
class NidSpace {
  const NidSpace._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// The one corner-radius scale.
class NidRadius {
  const NidRadius._();

  /// Cards, headers, empty states — the default surface corner.
  static const double card = 8;

  /// Fully rounded pills.
  static const double pill = 999;

  /// The framed brand badge lockup.
  static const double badge = 14;
}
