import 'dart:typed_data';

import 'package:absensi_mobile/screens/login_screen.dart';
import 'package:absensi_mobile/app_theme.dart';
import 'package:absensi_mobile/services/selfie_image.dart';
import 'package:absensi_mobile/widgets/ui.dart';
import 'package:absensi_mobile/widgets/app_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:absensi_mobile/theme_preferences.dart';

void main() {
  test('theme preference defaults to system and persists selections', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await loadThemeMode(), ThemeMode.system);

    await saveThemeMode(ThemeMode.dark);
    expect(await loadThemeMode(), ThemeMode.dark);

    await saveThemeMode(ThemeMode.light);
    expect(await loadThemeMode(), ThemeMode.light);

    await saveThemeMode(ThemeMode.system);
    expect(await loadThemeMode(), ThemeMode.system);
  });

  test('app themes support light and dark system brightness', () {
    expect(buildAppTheme().brightness, Brightness.light);
    expect(buildAppDarkTheme().brightness, Brightness.dark);
  });

  test('selfie capture mirrors the camera image horizontally', () {
    final source = img.Image(width: 64, height: 32);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgb(x, y, x < 32 ? 255 : 0, 0, x < 32 ? 0 : 255);
      }
    }

    final mirrored = img.decodeImage(
      mirrorSelfieImage(Uint8List.fromList(img.encodePng(source))),
    );

    expect(mirrored, isNotNull);
    expect(
      mirrored!.getPixel(8, 16).b,
      greaterThan(mirrored.getPixel(8, 16).r),
    );
    expect(
      mirrored.getPixel(56, 16).r,
      greaterThan(mirrored.getPixel(56, 16).b),
    );
  });

  testWidgets('app splash shows brand and version without a spinner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AppSplashScreen()));

    expect(find.text('Absensi BMT'), findsOneWidget);
    expect(find.text('Versi 1.0.0'), findsOneWidget);
    expect(find.bySemanticsLabel('Logo BMT Cinde Barokah'), findsOneWidget);
    expect(
      tester.getCenter(find.bySemanticsLabel('Logo BMT Cinde Barokah')).dx,
      180,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app splash follows dark system theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        darkTheme: buildAppDarkTheme(),
        themeMode: ThemeMode.dark,
        home: const AppSplashScreen(),
      ),
    );

    final logo = tester.widget<Image>(find.byType(Image));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFF18211C),
    );
    expect(
      (logo.image as AssetImage).assetName,
      'assets/images/logo_bmt_transparent.png',
    );
    expect(find.text('Absensi BMT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login screen renders and validates required fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onLoggedIn: () async {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('BMT CINDE BAROKAH'), findsOneWidget);
    expect(find.bySemanticsLabel('Logo BMT Cinde Barokah'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('nama@bmtcindebarokah.co.id'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Password wajib diisi.'), findsOneWidget);
  });

  testWidgets('attendance summary fits a narrow mobile screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: ResponsivePage(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  child: StatGrid(
                    items: const [
                      StatGridItem(
                        value: '12',
                        label: 'Tepat Waktu',
                        color: Colors.green,
                      ),
                      StatGridItem(
                        value: '2',
                        label: 'Terlambat',
                        color: Colors.red,
                      ),
                      StatGridItem(
                        value: '1',
                        label: 'Hari Izin',
                        color: Colors.orange,
                      ),
                      StatGridItem(
                        value: '20',
                        label: 'Hari Kerja',
                        color: brandPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tepat Waktu'), findsOneWidget);
    expect(find.text('Hari Kerja'), findsOneWidget);
  });
}
