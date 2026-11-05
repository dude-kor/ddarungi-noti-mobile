import 'package:ddarungi_noti/core/theme/app_colors.dart';
import 'package:ddarungi_noti/core/utils/hangul_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HangulUtils.extractChosung', () {
    test('keeps non-Hangul characters', () {
      expect(HangulUtils.extractChosung('망원역 1번출구'), 'ㅁㅇㅇ 1ㅂㅊㄱ');
    });
  });

  group('HangulUtils.isChosungOnly', () {
    test('detects chosung queries', () {
      expect(HangulUtils.isChosungOnly('ㅁㅇㅇ'), isTrue);
      expect(HangulUtils.isChosungOnly('ㅁ ㅇ'), isTrue);
      expect(HangulUtils.isChosungOnly('망원'), isFalse);
      expect(HangulUtils.isChosungOnly('102'), isFalse);
      expect(HangulUtils.isChosungOnly(''), isFalse);
    });
  });

  group('HangulUtils.matches', () {
    const name = '망원역 1번출구 앞';
    test('chosung', () {
      expect(HangulUtils.matches(name, 'ㅁㅇㅇ'), isTrue);
      expect(HangulUtils.matches('합정역 5번출구 앞', 'ㅎㅈ'), isTrue);
      expect(HangulUtils.matches('합정역 5번출구 앞', 'ㅁㅇㅇ'), isFalse);
    });
    test('plain text and numbers', () {
      expect(HangulUtils.matches(name, '망원'), isTrue);
      expect(HangulUtils.matches(name, '1번출구'), isTrue);
      expect(HangulUtils.matches('102. $name', '102'), isTrue);
      expect(HangulUtils.matches(name, '합정'), isFalse);
    });
    test('half-composed input', () {
      expect(HangulUtils.matches(name, '망ㅇ'), isTrue);
      expect(HangulUtils.matches(name, '마'), isTrue); // 마 -> 망 while typing
      expect(HangulUtils.matches(name, '모'), isFalse);
    });
    test('empty query never matches', () {
      expect(HangulUtils.matches(name, ''), isFalse);
      expect(HangulUtils.matches(name, '   '), isFalse);
    });
  });

  group('AppColors.toneFor', () {
    test('follows the spec thresholds', () {
      expect(identical(AppColors.toneFor(4), AppColors.available), isTrue);
      expect(identical(AppColors.toneFor(3), AppColors.warning), isTrue);
      expect(identical(AppColors.toneFor(1), AppColors.warning), isTrue);
      expect(identical(AppColors.toneFor(0), AppColors.danger), isTrue);
      expect(identical(AppColors.toneFor(null), AppColors.disabled), isTrue);
    });
    test('hex output', () {
      expect(AppColors.danger.textHex, '#EF4444');
      expect(AppColors.available.surfaceLightHex, '#F0FDF4');
    });
  });
}
