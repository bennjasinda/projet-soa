import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/task_queries.dart';
import 'task_detail_screen.dart';
import 'edit_task_screen.dart';

class AllTasksTab extends StatelessWidget {
  const AllTasksTab({super.key});

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'HIGH':
        return 'Haute';
      case 'MEDIUM':
        return 'Moyenne';
      case 'LOW':
        return 'Basse';
      default:
        return priority;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = dateString.split('T')[0];
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(TaskQueries.getTasks),
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
              ],
            ),
          );
        }

        final tasks = result.data?['tasks'] as List<dynamic>? ?? [];
        
        // Trier par date (plus récentes en premier)
        final sortedTasks = List<dynamic>.from(tasks);
        sortedTasks.sort((a, b) {
          final aDate = a['datalimited'] ?? a['createdAt'];
          final bDate = b['datalimited'] ?? b['createdAt'];
          if (aDate != null && bDate != null) {
            return bDate.toString().compareTo(aDate.toString());
          }
          return 0;
        });

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Text(
                    'Toutes les tâches',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sortedTasks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucune tâche',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Mutation(
                      options: MutationOptions(
                        document: gql(TaskQueries.toggleTaskComplete),
                        onCompleted: (data) {
                          if (refetch != null) refetch();
                        },
                      ),
                      builder: (runMutation, mutationResult) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            if (refetch != null) await refetch();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sortedTasks.length,
                            itemBuilder: (context, index) {
                              final task = sortedTasks[index];
                              final isCompleted = task['completed'] ?? false;
                              final priority = task['priority'] ?? 'MEDIUM';
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: isCompleted,
                                    onChanged: (_) => runMutation({'id': task['id']}),
                                    activeColor: Colors.teal,
                                  ),
                                  title: Text(
                                    task['title'] ?? '',
                                    style: TextStyle(
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: isCompleted ? Colors.grey : Colors.black,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (task['decription'] != null &&
                                          task['decription'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            task['decription'],
                                            style: TextStyle(
                                              color: isCompleted
                                                  ? Colors.grey
                                                  : Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(priority)
                                                  .withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _getPriorityLabel(priority),
                                              style: TextStyle(
                                                color: _getPriorityColor(priority),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (task['datalimited'] != null) ...[
                                            const SizedBox(width: 8),
                                            const Icon(Icons.calendar_today,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate(task['datalimited']),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility, size: 20),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TaskDetailScreen(
                                                task: task,
                                                onTaskUpdated: () {
                                                  if (refetch != null) refetch();
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditTaskScreen(
                                                task: task,
                                                onTaskUpdated: () {
                                                  if (refetch != null) refetch();
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                        onPressed: () {
                                          _showDeleteDialog(context, task['id'], refetch);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String taskId, Function? refetch) {
    showDialog(
      context: context,
      builder: (context) => Mutation(
        options: MutationOptions(
          document: gql(TaskQueries.deleteTask),
          onCompleted: (data) {
            if (refetch != null) refetch();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tâche supprimée avec succès')),
            );
          },
          onError: (error) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  error?.graphqlErrors.isNotEmpty == true
                      ? error!.graphqlErrors.first.message
                      : 'Erreur lors de la suppression',
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
        builder: (runMutation, result) {
          return AlertDialog(
            title: const Text('Supprimer la tâche'),
            content: const Text('Êtes-vous sûr de vouloir supprimer cette tâche ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: result?.isLoading == true
                    ? null
                    : () => runMutation({'id': taskId}),
                child: result?.isLoading == true
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }
}

