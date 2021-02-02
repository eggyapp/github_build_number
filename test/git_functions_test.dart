import 'package:github_build_number/git_functions.dart';
import 'package:test/test.dart';

void main() {
  group('parse github url', () {
    test('ssh url', () {
      final url = 'git@github.com:eggyapp/eggy-flutter.git';
      expect(parseGithubUrl(url), equals('eggyapp/eggy-flutter'));
    });

    test('starts with https github domain', () {
      final url = 'https://github.com/eggyapp/eggy-flutter.git';
      expect(parseGithubUrl(url), equals('eggyapp/eggy-flutter'));
    });

    test('starts with https org @ github', () {
      final url = 'https://eggyapp@github.com/eggyapp/eggy-flutter';
      expect(parseGithubUrl(url), equals('eggyapp/eggy-flutter'));
    });
  });
}
