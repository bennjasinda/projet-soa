// services/notification_queries.dart
class NotificationQueries {
  static const String getNotifications = '''
    query GetNotifications {
      notifications {
        id
        message
        type
        read
        createdAt
      }
    }
  ''';

  static const String getUnreadNotifications = '''
    query GetUnreadNotifications {
      unreadNotifications {
        id
        message
        type
        read
        createdAt
      }
    }
  ''';

  static const String markNotificationAsRead = '''
    mutation MarkNotificationAsRead(\$id: ID!) {
      markNotificationAsRead(id: \$id) {
        id
        read
      }
    }
  ''';

  static const String markAllNotificationsAsRead = '''
    mutation MarkAllNotificationsAsRead {
      markAllNotificationsAsRead {
        id
        read
      }
    }
  ''';

  static const String deleteNotification = '''
    mutation DeleteNotification(\$id: ID!) {
      deleteNotification(id: \$id)
    }
  ''';
}