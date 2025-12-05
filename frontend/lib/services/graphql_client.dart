import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class GraphQLService {
  static const String _backendHost = '10.236.41.189';
  static const int _backendPort = 4000;

  static String getGraphQLUrl() {
    return 'http://$_backendHost:$_backendPort/graphql';
  }

  static HttpLink createHttpLink() {
    final client = http.Client();
    return HttpLink(
      getGraphQLUrl(),
      defaultHeaders: {
        'Content-Type': 'application/json',
      },
      httpClient: client,
    );
  }

  static AuthLink createAuthLink() {
    return AuthLink(
      getToken: () async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        return token != null ? 'Bearer $token' : null;
      },
    );
  }

  static Link createLink() {
    final authLink = createAuthLink();
    final httpLink = createHttpLink();
    return authLink.concat(httpLink);
  }

  static ValueNotifier<GraphQLClient> createClient() {
    return ValueNotifier<GraphQLClient>(
      GraphQLClient(
        cache: GraphQLCache(),
        link: createLink(),
      ),
    );
  }
}

