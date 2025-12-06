import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/task_queries.dart';

class TaskDetailScreen extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onTaskUpdated;

  const TaskDetailScreen({
    super.key,
    required this.task,
    this.onTaskUpdated,
  });

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

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required Widget content,
    Color? iconColor,
  }) {
    return Container(
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
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor?.withOpacity(0.1) ?? Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = task['completed'] ?? false;
    final priority = task['priority'] ?? 'MEDIUM';

    return Mutation(
      options: MutationOptions(
        document: gql(TaskQueries.toggleTaskComplete),
        onCompleted: (data) {
          if (onTaskUpdated != null) onTaskUpdated!();
          Navigator.pop(context);
        },
      ),
      builder: (runMutation, result) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Détails de la tâche',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => runMutation({'id': task['id']}),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade300,
                        width: 2,
                      ),
                      color: isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Container(
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
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task['title'] ?? 'Sans titre',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: isCompleted ? Colors.grey.shade400 : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Description
                if (task['decription'] != null && task['decription'].toString().isNotEmpty)
                  Column(
                    children: [
                      _buildDetailCard(
                        icon: Icons.description_outlined,
                        title: 'Description',
                        iconColor: Colors.purple.shade600,
                        content: Text(
                          task['decription'],
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // Priorité
                _buildDetailCard(
                  icon: Icons.flag_outlined,
                  title: 'Priorité',
                  iconColor: _getPriorityColor(priority),
                  content: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityBackgroundColor(priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getPriorityLabel(priority),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getPriorityColor(priority),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

           

                // Statut
                _buildDetailCard(
                  icon: Icons.info_outline,
                  title: 'Statut',
                  iconColor: isCompleted ? Colors.green.shade600 : Colors.orange.shade600,
                  content: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.access_time,
                          color: isCompleted ? Colors.green.shade600 : Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCompleted ? 'Terminée' : 'En cours',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? Colors.green.shade600
                                      : Colors.orange.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isCompleted
                                    ? 'Cette tâche est marquée comme terminée'
                                    : 'Cette tâche est en cours de réalisation',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Bouton de retour
                Container(
                  width: double.infinity,
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
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Retour à la liste',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}