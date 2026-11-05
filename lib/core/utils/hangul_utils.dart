/// Hangul helpers for the station search (SCR-04): chosung matching ('ㅁㅇㅇ' -> '망원역') plus
/// as-you-type matching for half-composed input ('망ㅇ', '마').
abstract final class HangulUtils {
  static const List<String> _cho = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
    'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  ];
  static const int _syllableStart = 0xAC00; // 가
  static const int _syllableEnd = 0xD7A3; // 힣
  static const int _perChosung = 588; // 21 jungseong * 28 jongseong
  static const int _perJungseong = 28;

  static bool _isSyllable(int code) => code >= _syllableStart && code <= _syllableEnd;
  static bool _isChosungCode(int code) => _cho.any((c) => c.codeUnitAt(0) == code);
  static int _choCode(int syllable) => _cho[(syllable - _syllableStart) ~/ _perChosung].codeUnitAt(0);

  /// '망원역 1번출구' -> 'ㅁㅇㅇ 1ㅂㅊㄱ' (non-Hangul characters are kept).
  static String extractChosung(String text) {
    final out = StringBuffer();
    for (final unit in text.codeUnits) {
      out.writeCharCode(_isSyllable(unit) ? _choCode(unit) : unit);
    }
    return out.toString();
  }

  /// True when every non-space character of [text] is a chosung consonant.
  static bool isChosungOnly(String text) {
    final units = _normalize(text);
    return units.isNotEmpty && units.every(_isChosungCode);
  }

  /// Does [text] contain [query]? Case-insensitive, ignores whitespace. Each query character may be
  ///  - the same character,
  ///  - a chosung consonant standing for any syllable that starts with it, or
  ///  - (last character only) a syllable without a final consonant, standing for any syllable with the
  ///    same initial + vowel, so '마' matches '망' while the user is still typing.
  static bool matches(String text, String query) {
    final t = _normalize(text);
    final q = _normalize(query);
    if (q.isEmpty || q.length > t.length) return false;
    for (var start = 0; start <= t.length - q.length; start++) {
      if (_matchesAt(t, q, start)) return true;
    }
    return false;
  }

  static bool _matchesAt(List<int> t, List<int> q, int start) {
    for (var i = 0; i < q.length; i++) {
      final tc = t[start + i];
      final qc = q[i];
      if (tc == qc) continue;
      if (_isChosungCode(qc) && _isSyllable(tc) && _choCode(tc) == qc) continue;
      if (i == q.length - 1 && _isSyllable(qc) && _isSyllable(tc)) {
        final qi = qc - _syllableStart;
        final ti = tc - _syllableStart;
        if (qi % _perJungseong == 0 && qi ~/ _perJungseong == ti ~/ _perJungseong) continue;
      }
      return false;
    }
    return true;
  }

  static List<int> _normalize(String s) =>
      s.toLowerCase().codeUnits.where((u) => u != 0x20 && u != 0x09 && u != 0x0A).toList();
}
