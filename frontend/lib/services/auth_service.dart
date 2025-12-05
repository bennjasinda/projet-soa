import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String loginMutation = '''
    mutation Login(\$email: String!, \$password: String!) {
      login(email: \$email, password: \$password) {
        token
        user {
          id
          email
          firstName
          lastName
        }
      }
    }
  ''';

  static const String signupMutation = '''
    mutation Signup(
      \$email: String!
      \$password: String!
      \$lastName: String!
      \$firstName: String!
    ) {
      signup(
        email: \$email
        password: \$password
        lastName: \$lastName
        firstName: \$firstName
      ) {
        token
        user {
          id
          email
          lastName
          firstName
        }
      }
    }
  ''';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}

