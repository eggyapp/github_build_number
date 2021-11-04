
import 'dart:io';

Future<int> localBuildNumber({
  /// e.g. branch, tag, HEAD
  required final String gitObject,
  final String? workingDir,
}) async {
  final result = await Process.run(
    'git',
    [
      'rev-list',
      gitObject,
      '--count',
    ],
    workingDirectory: workingDir,
  );

  final stdout = result.stdout?.toString() ?? '';
  if (stdout.isEmpty) {
    return 0;
  }

  return int.parse(stdout);
}

Future<String> versionName({
  final String? workingDir,
}) async {
  final result = await Process.run(
    'git',
    [
      'describe',
      '--tags',
    ],
    workingDirectory: workingDir,
  );

  return result.stdout.toString().trim();
}

/// returns '<username>/<repo>'
/// e.g. 'eggyapp/eggy-flutter'
Future<String> githubPath({
  final String? workingDir,
}) async {
  final result = await Process.run(
    'git',
    [
      'remote',
      'get-url',
      'origin',
    ],
    workingDirectory: workingDir,
  );

  final url = result.stdout?.toString().trim() ?? '';
  if (url.isEmpty) {
    throw 'No remote found at path ${workingDir ?? '.'}';
  }

  return parseGithubUrl(url);
}

// returns the org/repo, e.g.
// eggyapp/eggy-flutter
String parseGithubUrl(String url) {
  const githubDomain = 'https://github.com/';

  /// https://github.com/eggyapp/eggy-flutter.git
  if (url.startsWith(githubDomain)) {
    return url.replaceFirst(githubDomain, '').replaceAll('.git', '');
  }
  /// https://eggyapp@github.com/eggyapp/eggy-flutter
  else if (url.startsWith('https://')) {
    return Uri.parse(url).pathSegments.join('/');
  }
  /// git@github.com:eggyapp/eggy-flutter.git
  else {
    return url.split(':').last.replaceAll('.git', '');
  }
}

// returns the current branch name or an empty string
Future<String> currentBranch({
  final String? workingDir,
}) async {
  final result = await Process.run(
    'git',
    [
      'branch',
      '--show-current',
    ],
    workingDirectory: workingDir,
  );

  return result.stdout?.toString().trim() ?? '';
}
