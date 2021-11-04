import 'dart:io';
import 'package:github_build_number/git_functions.dart';
import 'package:github_build_number/github_build_number.dart';

extension ParseArgs on Iterable<String> {
  String parse(
    final String argName, {
    required String Function() orElse,
  }) {
    final arg = firstWhere((it) => it.startsWith(argName), orElse: orElse)
        .split('=')
        .last;

    return arg;
  }
}

Future<void> main(List<String> arguments) async {
  const versionNameProgram = 'version-name';
  const buildNumberProgram = 'build-number';

  if (arguments.isEmpty) {
    stderr.writeln(
      '''
Program is required
===
$versionNameProgram
---
Outputs the version name based on the most recent tag.


$buildNumberProgram
---
Outputs the build number based on the number of accessible commits from the 
current branch.

If a github api token is provided the build number will be fetched from github, this is
useful to ensure the correct build number on CI machines that perform shallow clones.

token='<github api token>'

Token can also be set via the environment variable: GITHUB_API_TOKEN

''',);
    exit(1);
  }

  final program = arguments.first;
  final workingDir = arguments.parse(
    'workingDir',
    orElse: () => Directory.current.path,
  );
  final verbose = arguments.contains('-v');

  if (verbose) {
    stderr.writeln("-> Running program '$program' in workingDir '$workingDir'");
  }

  // check if an api key is provided and if so lookup build number from remote
  // so we don't need to pass in a bunch of args
  // - look up branch from local git
  // - look up remote details from git remote

  switch(program) {
    case versionNameProgram:
      final vn = await versionName(
        workingDir: workingDir,
      );
      stdout.writeln(vn);
      exit(0);
    case buildNumberProgram:
      final gitObject = await currentBranch(workingDir: workingDir);
      final token = arguments.parse(
        'token',
        orElse: () => Platform.environment['GITHUB_API_TOKEN'] ?? '',
      );
      if (verbose) {
        stderr.writeln('-> gitObject = $gitObject');
        stderr.writeln('-> token = $token');
      }

      if (token.trim().isNotEmpty) {
        if (verbose) {
          stderr.writeln('-> token found, fetching build number from github api');
        }

        try {
          // gives us the details we need for the api call
          final remote = await githubPath(
            workingDir: workingDir,
          ).then((it) => it.split('/'));

          final owner = remote.first;
          final repo = remote.last;
          if (verbose) {
            stderr.writeln('-> owner = $owner');
            stderr.writeln('-> repo = $repo');
          }

          final bn = await fetchCommitCount(
            token: token,
            owner: owner,
            repo: repo,
            gitObject: gitObject,
          );
          stdout.writeln(bn);
        } catch (e) {
          stderr.writeln('fetching commit count failed with error: "${e.toString()}"');
          exit(1);
        }
      } else {
        if (verbose) {
          stderr.writeln('-> no token found, calculating build number from local git history');
        }

        try {
          final bn = await localBuildNumber(
            gitObject: gitObject,
            workingDir: workingDir,
          );
          stdout.writeln(bn);
        } catch (e) {
          stderr.writeln('Unable to calculate local build number, git returned error: \n$e');
          exit(1);
        }
      }
      exit(0);
  }
}
