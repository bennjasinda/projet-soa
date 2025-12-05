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

  @override
  Widget build(BuildContext context) {
    final isCompleted = task['completed'] ?? false;
    final priority = task['priority'] ?? 'MEDIUM';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la tâche'),
      ),
      body: Mutation(
        options: MutationOptions(
          document: gql(TaskQueries.toggleTaskComplete),
          onCompleted: (data) {
            if (onTaskUpdated != null) onTaskUpdated!();
            Navigator.pop(context);
          },
        ),
        builder: (runMutation, result) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task['title'] ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isCompleted ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    Checkbox(
                      value: isCompleted,
                      onChanged: (_) => runMutation({'id': task['id']}),
                      activeColor: Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Description
                if (task['decription'] != null && task['decription'].toString().isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task['decription'],
                    style: TextStyle(
                      fontSize: 16,
                      color: isCompleted ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Priorité
                const Text(
                  'Priorité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getPriorityLabel(priority),
                    style: TextStyle(
                      color: _getPriorityColor(priority),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Date limite
                const Text(
                  'Date limite',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(task['datalimited']),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Statut
                const Text(
                  'Statut',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isCompleted ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCompleted ? 'Terminée' : 'En cours',
                      style: TextStyle(
                        fontSize: 16,
                        color: isCompleted ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Date de création
                const Text(
                  'Date de création',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(task['createdAt']),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

