// Guards the app-branding regression that shipped the default Flutter icon and
// a "Nguyenindoubt App" home-screen label on every platform (2026-07-12). These
// checks read the real platform manifests + icon assets from disk, so they fail
// if the brand mark or display name ever reverts. Pure file checks — no widget
// binding needed.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Parses a PNG's IHDR chunk → (width, height, colorType). colorType 2 =
/// truecolor (RGB, no alpha); 6 = truecolor+alpha. iOS app icons MUST be
/// opaque (no alpha) or the App Store rejects them, and the Flutter default
/// icon ships as RGBA — so "no alpha" doubles as a "not the default" guard.
({int width, int height, int colorType}) _readIhdr(File png) {
  final bytes = png.readAsBytesSync();
  // 8-byte signature, then length(4)+"IHDR"(4), then width(4) height(4) depth(1)
  // colorType(1). Width starts at offset 16.
  int u32(int o) =>
      (bytes[o] << 24) |
      (bytes[o + 1] << 16) |
      (bytes[o + 2] << 8) |
      bytes[o + 3];
  return (width: u32(16), height: u32(20), colorType: bytes[25]);
}

String _firstStringAfterKey(String plist, String key) {
  final keyIdx = plist.indexOf('<key>$key</key>');
  expect(keyIdx, greaterThanOrEqualTo(0), reason: 'missing <key>$key</key>');
  final match = RegExp(
    r'<string>(.*?)</string>',
  ).firstMatch(plist.substring(keyIdx));
  return match!.group(1)!;
}

void main() {
  const brand = 'NguyenInDoubt';
  final iconSet = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');

  test('iOS display name is the brand, not "Nguyenindoubt App"', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(_firstStringAfterKey(plist, 'CFBundleDisplayName'), brand);
  });

  test('Android launcher label is the brand', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final label = RegExp(
      r'android:label="([^"]*)"',
    ).firstMatch(manifest)!.group(1);
    expect(label, brand);
  });

  test('web manifest + title carry the brand name', () {
    final manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(manifest['name'], brand);
    expect(manifest['short_name'], brand);
    expect(
      File('web/index.html').readAsStringSync(),
      contains('<title>$brand'),
    );
  });

  test(
    'iOS marketing icon is a 1024 opaque PNG (no alpha, not the default)',
    () {
      final icon = File('${iconSet.path}/Icon-App-1024x1024@1x.png');
      expect(icon.existsSync(), isTrue);
      final ihdr = _readIhdr(icon);
      expect(ihdr.width, 1024);
      expect(ihdr.height, 1024);
      // colorType 6 (RGBA) is the Flutter-default icon and is App Store-invalid.
      expect(
        ihdr.colorType,
        isNot(6),
        reason: 'iOS icon must not have an alpha channel',
      );
    },
  );

  test('every AppIcon file in Contents.json exists at its declared size', () {
    final contents =
        jsonDecode(File('${iconSet.path}/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final image in (contents['images'] as List).cast<Map>()) {
      final filename = image['filename'] as String?;
      if (filename == null) continue;
      final file = File('${iconSet.path}/$filename');
      expect(file.existsSync(), isTrue, reason: 'missing $filename');
      // "20x20" @ "2x" => 40px. "83.5x83.5" @ "2x" => 167px.
      final basePt = double.parse((image['size'] as String).split('x').first);
      final scale = int.parse((image['scale'] as String).replaceAll('x', ''));
      final expected = (basePt * scale).round();
      final ihdr = _readIhdr(file);
      expect(ihdr.width, expected, reason: '$filename width');
      expect(ihdr.height, expected, reason: '$filename height');
      expect(
        ihdr.colorType,
        isNot(6),
        reason: '$filename must be opaque (no alpha)',
      );
    }
  });

  test('Android mipmaps carry a launcher icon at every density', () {
    const densities = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    densities.forEach((density, size) {
      final file = File(
        'android/app/src/main/res/mipmap-$density/ic_launcher.png',
      );
      expect(file.existsSync(), isTrue, reason: 'missing $density launcher');
      final ihdr = _readIhdr(file);
      expect(ihdr.width, size, reason: '$density launcher width');
    });
  });
}
