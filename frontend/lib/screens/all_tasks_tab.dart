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
        return const Color(0xFFFF4757);
      case 'MEDIUM':
        return const Color(0xFFFFA502);
      case 'LOW':
        return const Color(0xFF2ED573);
      default:
        return const Color(0xFF747D8C);
    }
  }

  Color _getPriorityBackgroundColor(String priority) {
    switch (priority) {
      case 'HIGH':
        return const Color(0xFFFF4757).withOpacity(0.1);
      case 'MEDIUM':
        return const Color(0xFFFFA502).withOpacity(0.1);
      case 'LOW':
        return const Color(0xFF2ED573).withOpacity(0.1);
      default:
        return const Color(0xFF747D8C).withOpacity(0.1);
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'HIGH':
        return 'Haute priorité';
      case 'MEDIUM':
        return 'Priorité moyenne';
      case 'LOW':
        return 'Basse priorité';
      default:
        return priority;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Non définie';
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 60,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune tâche',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Commencez par créer votre première tâche',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String taskId, Function? refetch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer la tâche',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        content: Text(
          'Cette action est irréversible. Êtes-vous sûr de vouloir supprimer cette tâche ?',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Mutation(
            options: MutationOptions(
              document: gql(TaskQueries.deleteTask),
              onCompleted: (data) {
                if (refetch != null) refetch();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Tâche supprimée avec succès'),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
            builder: (runMutation, result) {
              return TextButton(
                onPressed: result?.isLoading == true
                    ? null
                    : () => runMutation({'id': taskId}),
                child: result?.isLoading == true
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red.shade600,
                        ),
                      )
                    : Text(
                        'Supprimer',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
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
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6366F1),
            ),
          );
        }

        if (result.hasException) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Erreur de chargement des tâches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.exception?.graphqlErrors.first.message ?? "Veuillez réessayer",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => refetch?.call(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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

        return Container(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Toutes les tâches',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${tasks.length} tâche${tasks.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: sortedTasks.isEmpty
                    ? _buildEmptyState()
                    : Mutation(
                        options: MutationOptions(
                          document: gql(TaskQueries.toggleTaskComplete),
                          onCompleted: (data) {
                            if (refetch != null) refetch();
                          },
                        ),
                        builder: (runMutation, mutationResult) {
                          return RefreshIndicator(
                            color: const Color(0xFF6366F1),
                            onRefresh: () async {
                              if (refetch != null) await refetch();
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: sortedTasks.length,
                              itemBuilder: (context, index) {
                                final task = sortedTasks[index];
                                final isCompleted = task['completed'] ?? false;
                                final priority = task['priority'] ?? 'MEDIUM';
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.grey.shade100,
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
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
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // Checkbox
                                            GestureDetector(
                                              onTap: () => runMutation({'id': task['id']}),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isCompleted
                                                        ? const Color(0xFF10B981)
                                                        : Colors.grey.shade300,
                                                    width: 2,
                                                  ),
                                                  color: isCompleted
                                                      ? const Color(0xFF10B981)
                                                      : Colors.transparent,
                                                  boxShadow: isCompleted
                                                      ? [
                                                          BoxShadow(
                                                            color: const Color(0xFF10B981)
                                                                .withOpacity(0.3),
                                                            blurRadius: 8,
                                                          ),
                                                        ]
                                                      : [],
                                                ),
                                                child: isCompleted
                                                    ? const Icon(
                                                        Icons.check,
                                                        size: 16,
                                                        color: Colors.white,
                                                      )
                                                    : null,
                                              ),
                                            ),

                                            const SizedBox(width: 16),

                                            // Contenu
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              task['title'] ?? 'Sans titre',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w600,
                                                                decoration: isCompleted
                                                                    ? TextDecoration.lineThrough
                                                                    : TextDecoration.none,
                                                                color: isCompleted
                                                                    ? Colors.grey.shade400
                                                                    : Colors.black,
                                                              ),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            if (task['decription'] != null &&
                                                                task['decription'].toString().isNotEmpty)
                                                              Padding(
                                                                padding: const EdgeInsets.only(top: 6),
                                                                child: Text(
                                                                  task['decription'],
                                                                  style: TextStyle(
                                                                    fontSize: 13,
                                                                    color: isCompleted
                                                                        ? Colors.grey.shade400
                                                                        : Colors.grey.shade600,
                                                                    height: 1.4,
                                                                  ),
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: _getPriorityBackgroundColor(priority),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.circle,
                                                              size: 8,
                                                              color: _getPriorityColor(priority),
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              _getPriorityLabel(priority).split(' ')[0],
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w700,
                                                                color: _getPriorityColor(priority),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 12),

                                                  // Date et actions
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.calendar_today_outlined,
                                                        size: 14,
                                                        color: Colors.grey.shade500,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _formatDate(task['datalimited']),
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.visibility_outlined,
                                                          size: 18,
                                                          color: const Color(0xFF6366F1),
                                                        ),
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
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.edit_outlined,
                                                          size: 18,
                                                          color: Colors.orange.shade600,
                                                        ),
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
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.delete_outline,
                                                          size: 18,
                                                          color: Colors.red.shade400,
                                                        ),
                                                        onPressed: () {
                                                          _showDeleteDialog(context, task['id'], refetch);
                                                        },
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
          ),
        );
      },
    );
  }
}