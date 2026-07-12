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

  /// Interior padding for cards — a touch roomier than the page gutter.
  static const double cardPad = 18;

  /// Vertical rhythm between stacked cards / sections.
  static const double cardGap = 14;
}

/// The one corner-radius scale.
class NidRadius {
  const NidRadius._();

  /// Cards, headers, empty states — the default surface corner.
  static const double card = 16;

  /// Larger surfaces — hero cards, brand lockups.
  static const double cardLg = 18;

  /// Controls — buttons, inputs.
  static const double control = 14;

  /// Medium control corner — stepper buttons, time pills (mock 12px).
  static const double m12 = 12;

  /// Small tiles — bullet icon chips, mini indicators.
  static const double tile = 11;

  /// Fully rounded pills.
  static const double pill = 999;

  /// The framed brand badge lockup.
  static const double badge = 14;
}
