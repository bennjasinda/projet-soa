import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/task_queries.dart';
import '../components/add_task_form.dart';
import '../components/app_bar_with_notifications.dart';
import 'task_detail_screen.dart';
import 'edit_task_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String? _selectedPriority;
  String? _selectedStatus; // null, 'completed', 'in_progress'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // NOUVELLE MÉTHODE : Convertir timestamp ou chaîne en DateTime
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      // Si c'est un timestamp (nombre)
      if (dateValue is int || dateValue is String && RegExp(r'^\d+$').hasMatch(dateValue)) {
        final timestamp = int.parse(dateValue.toString());
        // Vérifier si c'est en millisecondes (13 chiffres) ou secondes (10 chiffres)
        if (timestamp > 1000000000000) {
          // Millisecondes
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else {
          // Secondes
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }
      // Si c'est une chaîne de date ISO
      else if (dateValue is String) {
        // Essayer de parser comme date ISO
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          // Essayer d'autres formats
          final parts = dateValue.split('-');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        }
      }
    } catch (e) {
      print('Erreur de parsing de date: $dateValue, erreur: $e');
    }
    return null;
  }

  bool _isToday(dynamic dateValue) {
    final date = _parseDate(dateValue);
    if (date == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    return taskDate.year == today.year &&
        taskDate.month == today.month &&
        taskDate.day == today.day;
  }

  List<dynamic> _filterTasks(List<dynamic> tasks) {
    final searchQuery = _searchController.text.toLowerCase();
    final todayTasks = tasks.where((task) {
      // Filtrer par date (aujourd'hui) - seulement par datalimited
      final datalimited = task['datalimited'];
      if (datalimited != null) {
        return _isToday(datalimited);
      }
      return false;
    }).toList();

    return todayTasks.where((task) {
      // Filtrer par statut
      final isCompleted = task['completed'] ?? false;
      if (_selectedStatus == 'completed' && !isCompleted) return false;
      if (_selectedStatus == 'in_progress' && isCompleted) return false;

      // Filtrer par priorité
      if (_selectedPriority != null && task['priority'] != _selectedPriority) {
        return false;
      }

      // Filtrer par recherche
      if (searchQuery.isNotEmpty) {
        final title = (task['title'] ?? '').toString().toLowerCase();
        if (!title.contains(searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Map<String, dynamic> _calculateStats(List<dynamic> tasks) {
    final todayTasks = tasks.where((task) {
      final datalimited = task['datalimited'];
      return datalimited != null && _isToday(datalimited);
    }).toList();

    int todayCount = todayTasks.length;
    int todayCompletedCount = 0;
    int todayInProgressCount = 0;

    for (var task in todayTasks) {
      final isCompleted = task['completed'] ?? false;
      if (isCompleted) {
        todayCompletedCount++;
      } else {
        todayInProgressCount++;
      }
    }

    // Calcul pour toutes les tâches
    int totalCompletedCount = 0;
    int totalInProgressCount = 0;
    int totalCount = tasks.length;

    for (var task in tasks) {
      final isCompleted = task['completed'] ?? false;
      if (isCompleted) {
        totalCompletedCount++;
      } else {
        totalInProgressCount++;
      }
    }

    final completionRate = totalCount > 0 
        ? (totalCompletedCount / totalCount * 100).round() 
        : 0;

    return {
      'todayCount': todayCount,
      'todayCompletedCount': todayCompletedCount,
      'todayInProgressCount': todayInProgressCount,
      'totalCompletedCount': totalCompletedCount,
      'totalInProgressCount': totalInProgressCount,
      'totalCount': totalCount,
      'completionRate': completionRate,
    };
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

  String _formatDate(dynamic dateValue) {
    final date = _parseDate(dateValue);
    if (date == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate.year == today.year && 
        taskDate.month == today.month && 
        taskDate.day == today.day) {
      return 'Aujourd\'hui';
    } else if (taskDate.year == tomorrow.year && 
               taskDate.month == tomorrow.month && 
               taskDate.day == tomorrow.day) {
      return 'Demain';
    } else {
      // Formater comme "6 déc."
      final months = ['', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 
                     'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
      return '${taskDate.day} ${months[taskDate.month]}';
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
      return timeString;
    } catch (e) {
      return timeString;
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: refetch != null ? () => refetch() : null,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final tasks = result.data?['tasks'] as List<dynamic>? ?? [];
        final stats = _calculateStats(tasks);
        final filteredTasks = _filterTasks(tasks);

        return Scaffold(
          appBar: const AppBarWithNotifications(title: 'TaskFlow'),
          body: Column(
            children: [
              // Statistiques
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tableau de bord',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cartes statistiques - Responsive
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        return isWide
                            ? Row(
                                children: [
                                  _StatCard(
                                    icon: Icons.today,
                                    iconColor: Colors.blue,
                                    value: '${stats['todayCount']}',
                                    label: 'Aujourd\'hui',
                                    isIconFilled: false,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatCard(
                                    icon: Icons.check_circle,
                                    iconColor: Colors.green,
                                    value: '${stats['todayCompletedCount']}',
                                    label: 'Terminées',
                                    isIconFilled: true,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatCard(
                                    icon: Icons.access_time,
                                    iconColor: Colors.orange,
                                    value: '${stats['todayInProgressCount']}',
                                    label: 'En cours',
                                    isIconFilled: false,
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _StatCard(
                                          icon: Icons.today,
                                          iconColor: Colors.blue,
                                          value: '${stats['todayCount']}',
                                          label: 'Aujourd\'hui',
                                          isIconFilled: false,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _StatCard(
                                          icon: Icons.check_circle,
                                          iconColor: Colors.green,
                                          value: '${stats['todayCompletedCount']}',
                                          label: 'Terminées',
                                          isIconFilled: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _StatCard(
                                          icon: Icons.access_time,
                                          iconColor: Colors.orange,
                                          value: '${stats['todayInProgressCount']}',
                                          label: 'En cours',
                                          isIconFilled: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Taux de complétion
                    Row(
                      children: [
                        const Text(
                          'Taux de complétion',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${stats['completionRate']}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: stats['completionRate'] / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              // Section tâches d'aujourd'hui
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
                child: Row(
                  children: [
                    const Text(
                      'Tâches d\'aujourd\'hui',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.teal),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => AddTaskForm(
                            onTaskCreated: () {
                              if (refetch != null) refetch();
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Filtres et recherche
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: InputDecoration(
                              labelText: 'Priorité',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Toutes')),
                              DropdownMenuItem(value: 'HIGH', child: Text('Haute')),
                              DropdownMenuItem(value: 'MEDIUM', child: Text('Moyenne')),
                              DropdownMenuItem(value: 'LOW', child: Text('Basse')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedPriority = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Statut',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Tous')),
                              DropdownMenuItem(value: 'completed', child: Text('Terminées')),
                              DropdownMenuItem(value: 'in_progress', child: Text('En cours')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Liste des tâches
              Expanded(
                child: filteredTasks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucune tâche pour aujourd\'hui',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ajoutez des tâches avec une date limite d\'aujourd\'hui',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
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
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                final isCompleted = task['completed'] ?? false;
                                final priority = task['priority'] ?? 'MEDIUM';
                                final title = task['title'] ?? '';
                                final description = task['decription'] ?? '';
                                final datalimited = task['datalimited'];
                                final timelimited = task['timelimited'];
                                
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: isCompleted,
                                      onChanged: (_) => runMutation({'id': task['id']}),
                                      activeColor: Colors.teal,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    title: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        color: isCompleted ? Colors.grey : Colors.black,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (description.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              description,
                                              style: TextStyle(
                                                color: isCompleted
                                                    ? Colors.grey
                                                    : Colors.black54,
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getPriorityColor(priority)
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
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
                                            if (datalimited != null) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.calendar_today, size: 12, color: Colors.blue),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatDate(datalimited),
                                                      style: const TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            if (timelimited != null && timelimited.toString().isNotEmpty) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.access_time, size: 12, color: Colors.purple),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatTime(timelimited.toString()),
                                                      style: const TextStyle(
                                                        color: Colors.purple,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
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
                                          icon: const Icon(Icons.visibility, size: 20, color: Colors.grey),
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
                                          tooltip: 'Voir les détails',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
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
                                          tooltip: 'Modifier',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                          onPressed: () {
                                            _showDeleteDialog(context, task['id'], refetch);
                                          },
                                          tooltip: 'Supprimer',
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
          ),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isIconFilled;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.isIconFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}