import 'package:flutter/material.dart';

/// Design tokens for the "Emerald Rail" theme — a premium card-room look
/// (deep felt, brass/gold accents, ivory cards). Single source of truth so
/// the palette never drifts into scattered hex literals across widgets.
class DurakColors {
  DurakColors._();

  // Felt (backgrounds)
  static const feltHighlight = Color(0xFF1E6B45);
  static const feltMid = Color(0xFF114C31);
  static const feltShadow = Color(0xFF071F15);
  static const feltDeepCorner = Color(0xFF030B08);

  // Brass / gold accent — the only accent hue in the app
  static const goldHighlight = Color(0xFFF6DE9B);
  static const goldCore = Color(0xFFD4AF37);
  static const goldShadow = Color(0xFF8A6423);

  // Card face
  static const ivory = Color(0xFFFBF6E8);
  static const cardHairline = Color(0xFFE7DCC0);
  static const cardBorder = Color(0xFFC9B98A);
  static const suitRed = Color(0xFFA6192E);
  static const suitBlack = Color(0xFF17181A);

  // Card back
  static const cardBackTop = Color(0xFF0E3B27);
  static const cardBackBottom = Color(0xFF062016);

  // Text on felt
  static const textPrimary = Color(0xFFF3EAD2);
  static const textSecondary = Color(0xFFB9AF93);
  static const textTertiary = Color(0xFF7D8A80);
  static const alertAmber = Color(0xFFF2A65A);
}
