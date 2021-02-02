import 'dart:io';
import 'package:github_build_number/git_functions.dart';
import 'package:github_build_number/github_build_number.dart';

extension ParseArgs on Iterable<String> {
  String parse(final String argName, {bool required = false}) {
    final arg = firstWhere((it) => it?.startsWith(argName), orElse: () => null)
        ?.split('=')
        ?.last;

    if (arg == null && required) {
      throw 'ERROR: missing required argument: $argName';
    }

    return arg;
  }
}

Future<void> main(List<String> arguments) async {
  const versionNameProgram = 'version-name';
  const buildNumberProgram = 'build-number';

  if (arguments.isEmpty) {
    stderr.writeln(('''
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
    
    '''));
    exit(1);
  }

  final program = arguments.first;
  final workingDir = arguments.parse('workingDir');

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
      break;
    case buildNumberProgram:
      final gitObject = await currentBranch(workingDir: workingDir);
      final token = arguments.parse('token');

      if (token != null && token.isNotEmpty) {
        try {
          // gives us the details we need for the api call
          final remote = await githubPath(
            workingDir: workingDir,
          ).then((it) => it.split('/'));

          final bn = await fetchCommitCount(
            token: token,
            owner: remote.first,
            repo: remote.last,
            gitObject: gitObject,
          );
          stdout.writeln(bn);
        } catch (e, s) {
          stderr.writeln('fetching commit count failed with error: "${e?.toString()}"');
          exit(1);
        }
      } else {
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
      break;
  }
}
