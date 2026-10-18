import 'package:chat_app_ai/core/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provides English and Arabic strings', () {
    expect(AppStrings(const Locale('en')).text('home'), 'Home');
    expect(AppStrings(const Locale('ar')).text('home'), 'الرئيسية');
    expect(AppStrings(const Locale('en')).text('goodMorning'), 'Good morning,');
    expect(
      AppStrings(const Locale('ar')).text('firstWelcomeTitle'),
      'مرحبًا بك في أورا!',
    );
  });
}
