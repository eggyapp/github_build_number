import 'package:graphql/client.dart';

Future<int> fetchCommitCount({
  required final String token,
  required final String owner,
  required final String repo,
  required final String gitObject,
}) async {
  // print('test');
  final httpLink = HttpLink(
    'https://api.github.com/graphql',
  );
  final authLink = AuthLink(
    getToken: () async => 'Bearer $token',
  );

  final _link = authLink.concat(httpLink);
  final client = GraphQLClient(
    /// **NOTE** The default store is the InMemoryStore, which does NOT persist to disk
    cache: GraphQLCache(),
    link: _link,
  );

  final options = QueryOptions(
    document: gql('''
{
  repository(owner: "$owner", name: "$repo") {
    name
    refs(first: 100, refPrefix: "refs/heads/", query: "$gitObject") {
      edges {
        node {
          name
          target {
            ... on Commit {
              history(first: 0) {
                totalCount
              }
            }
          }
        }
      }
    }
  }
}
''',
    ),
  );

  final result = await client.query(options);
  final exception = result.exception;
  if (exception != null) {
    throw exception;
  } else {
    /// example return object
    /// {
    //     "repository": {
    //       "name": "eggy-flutter",
    //       "refs": {
    //         "edges": [
    //           {
    //             "node": {
    //               "name": "master",
    //               "target": {
    //                 "history": {
    //                   "totalCount": 87
    //                 }
    //               }
    //             }
    //           }
    //         ]
    //       }
    //     }
    //   }
    return result.data!['repository']['refs']['edges'].firstWhere((it) => it['node']['name'] == gitObject)['node']['target']['history']['totalCount'] as int;
  }
}
