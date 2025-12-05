class UserQueries {
  static const String getMe = '''
    query GetMe {
      me {
        id
        email
        firstName
        lastName
      }
    }
  ''';

  static const String updateUser = '''
    mutation UpdateUser(
      \$email: String
      \$firstName: String
      \$lastName: String
      \$password: String
    ) {
      updateUser(
        email: \$email
        firstName: \$firstName
        lastName: \$lastName
        password: \$password
      ) {
        id
        email
        firstName
        lastName
      }
    }
  ''';
}

