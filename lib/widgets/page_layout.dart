import 'package:flutter/material.dart';

// Ukuran layar dan jarak yang dipakai bersama oleh halaman-halaman aplikasi.
class PageLayout {
  PageLayout._({
    required this.width,
    required this.height,
    required this.maxWidth,
    required this.paddingRatio,
  });

  factory PageLayout.of(
    BuildContext context, {
    double maxWidth = 900,
    double paddingRatio = 0.05,
  }) {
    final size = MediaQuery.sizeOf(context);
    return PageLayout._(
      width: size.width,
      height: size.height,
      maxWidth: maxWidth,
      paddingRatio: paddingRatio,
    );
  }

  final double width;
  final double height;
  final double maxWidth;
  final double paddingRatio;

  bool get isWide => width >= 600;
  bool get isNarrow => width < 360;
  bool get isShort => height < 600;
  double get sidePadding => width * paddingRatio;
  double get gap => isWide ? 20 : 14;
}
