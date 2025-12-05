import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/notification_queries.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'À l\'instant';
          }
          return 'Il y a ${difference.inMinutes} min';
        }
        return 'Il y a ${difference.inHours} h';
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Mutation(
            options: MutationOptions(
              document: gql(NotificationQueries.markAllNotificationsAsRead),
              onCompleted: (data) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Toutes les notifications ont été marquées comme lues')),
                );
              },
            ),
            builder: (runMutation, result) {
              return IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: result?.isLoading == true
                    ? null
                    : () => runMutation({}),
                tooltip: 'Tout marquer comme lu',
              );
            },
          ),
        ],
      ),
      body: Query(
        options: QueryOptions(
          document: gql(NotificationQueries.getNotifications),
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
        builder: (QueryResult result, {refetch, fetchMore}) {
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (result.hasException) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${result.exception?.graphqlErrors.first.message ?? "Erreur inconnue"}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: refetch != null ? () => refetch() : null,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final notifications = result.data?['notifications'] as List<dynamic>? ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (refetch != null) await refetch();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['read'] ?? false;
                final type = notification['type'] ?? 'INFO';
                final isWarning = type == 'WARNING';

                return Mutation(
                  options: MutationOptions(
                    document: gql(NotificationQueries.markNotificationAsRead),
                    onCompleted: (data) {
                      if (refetch != null) refetch();
                    },
                  ),
                  builder: (runMarkAsRead, markResult) {
                    return Mutation(
                      options: MutationOptions(
                        document: gql(NotificationQueries.deleteNotification),
                        onCompleted: (data) {
                          if (refetch != null) refetch();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification supprimée')),
                          );
                        },
                      ),
                      builder: (runDelete, deleteResult) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isRead ? Colors.white : Colors.blue[50],
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isWarning
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.teal.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isWarning ? Icons.warning : Icons.info,
                                color: isWarning ? Colors.red : Colors.teal,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              notification['message'] ?? '',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(notification['createdAt']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isRead)
                                  IconButton(
                                    icon: const Icon(Icons.check, size: 20),
                                    onPressed: markResult?.isLoading == true
                                        ? null
                                        : () => runMarkAsRead({'id': notification['id']}),
                                    tooltip: 'Marquer comme lu',
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: deleteResult?.isLoading == true
                                      ? null
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (dialogContext) => AlertDialog(
                                              title: const Text('Supprimer la notification'),
                                              content: const Text(
                                                'Êtes-vous sûr de vouloir supprimer cette notification ?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(dialogContext),
                                                  child: const Text('Annuler'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(dialogContext);
                                                    runDelete({'id': notification['id']});
                                                  },
                                                  child: const Text(
                                                    'Supprimer',
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                  tooltip: 'Supprimer',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

