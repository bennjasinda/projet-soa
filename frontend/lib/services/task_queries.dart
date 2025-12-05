class TaskQueries {
  static const String getTasks = '''
    query GetTasks {
      tasks {
        id
        title
        decription
        completed
        datalimited
        priority
        createdAt
        user {
          id
          email
        }
      }
    }
  ''';

  static const String createTask = '''
    mutation CreateTask(
      \$title: String!
      \$decription: String!
      \$priority: Priority!
      \$datalimited: String
    ) {
      createTask(
        title: \$title
        decription: \$decription
        priority: \$priority
        datalimited: \$datalimited
      ) {
        id
        title
        decription
        completed
        datalimited
        priority
        createdAt
        user {
          id
          email
        }
      }
    }
  ''';

  static const String toggleTaskComplete = '''
    mutation ToggleTaskComplete(\$id: ID!) {
      toggleTaskComplete(id: \$id) {
        id
        completed
      }
    }
  ''';

  static const String deleteTask = '''
    mutation DeleteTask(\$id: ID!) {
      deleteTask(id: \$id)
    }
  ''';

  static const String updateTask = '''
    mutation UpdateTask(
      \$id: ID!
      \$title: String
      \$decription: String
      \$datalimited: String
      \$priority: Priority
    ) {
      updateTask(
        id: \$id
        title: \$title
        decription: \$decription
        datalimited: \$datalimited
        priority: \$priority
      ) {
        id
        title
        decription
        completed
        datalimited
        priority
        createdAt
        user {
          id
          email
        }
      }
    }
  ''';
}
