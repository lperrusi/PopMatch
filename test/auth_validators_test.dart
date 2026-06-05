import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/utils/auth_validators.dart';

void main() {
  group('AuthValidators.email', () {
    test('rejects empty', () => expect(AuthValidators.email(''), isNotNull));
    test('rejects malformed',
        () => expect(AuthValidators.email('not-an-email'), isNotNull));
    test('rejects missing tld',
        () => expect(AuthValidators.email('a@b'), isNotNull));
    test('accepts valid',
        () => expect(AuthValidators.email('user@example.com'), isNull));
    test('accepts plus-alias',
        () => expect(AuthValidators.email('user+b@example.com'), isNull));
    test('trims whitespace',
        () => expect(AuthValidators.email('  user@example.com '), isNull));
  });

  group('AuthValidators.password', () {
    test('rejects empty', () => expect(AuthValidators.password(''), isNotNull));
    test('rejects < 6 chars',
        () => expect(AuthValidators.password('12345'), isNotNull));
    test('accepts >= 6 chars',
        () => expect(AuthValidators.password('123456'), isNull));
  });

  group('AuthValidators.loginPassword', () {
    test('only requires non-empty',
        () => expect(AuthValidators.loginPassword('x'), isNull));
    test('rejects empty',
        () => expect(AuthValidators.loginPassword(''), isNotNull));
  });

  group('AuthValidators.confirmPassword', () {
    test('matches', () {
      expect(AuthValidators.confirmPassword('abcdef', 'abcdef'), isNull);
    });
    test('mismatch', () {
      expect(AuthValidators.confirmPassword('abcdef', 'abcxyz'), isNotNull);
    });
    test('empty', () {
      expect(AuthValidators.confirmPassword('', 'abcdef'), isNotNull);
    });
  });

  group('AuthValidators.code', () {
    test('accepts 6 digits',
        () => expect(AuthValidators.code('123456'), isNull));
    test('rejects 5 digits',
        () => expect(AuthValidators.code('12345'), isNotNull));
    test('rejects non-numeric',
        () => expect(AuthValidators.code('12a456'), isNotNull));
  });

  group('AuthValidators.displayName', () {
    test('rejects empty',
        () => expect(AuthValidators.displayName(''), isNotNull));
    test('rejects 1 char',
        () => expect(AuthValidators.displayName('A'), isNotNull));
    test('accepts >= 2 chars',
        () => expect(AuthValidators.displayName('Al'), isNull));
  });

  group('estimatePasswordStrength', () {
    test('short is weak',
        () => expect(estimatePasswordStrength('abc'), PasswordStrength.weak));
    test('long + varied is strong', () {
      expect(estimatePasswordStrength('Abcdef12!@'), PasswordStrength.strong);
    });
    test('medium is fair', () {
      expect(estimatePasswordStrength('abcd1234'), PasswordStrength.fair);
    });
  });
}
