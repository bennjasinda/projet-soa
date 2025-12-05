import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/task_queries.dart';
import 'task_detail_screen.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _selectedDate = DateTime.now();

  // Méthode pour parser les dates (timestamps ou strings)
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      // Si c'est un timestamp (nombre)
      if (dateValue is int || dateValue is String && RegExp(r'^\d+$').hasMatch(dateValue)) {
        final timestamp = int.parse(dateValue.toString());
        if (timestamp > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }
      // Si c'est une chaîne de date ISO
      else if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
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

  List<dynamic> _getTasksForDate(List<dynamic> tasks, DateTime date) {
    return tasks.where((task) {
      final datalimited = task['datalimited'];
      if (datalimited != null) {
        final taskDate = _parseDate(datalimited);
        if (taskDate != null) {
          return taskDate.year == date.year &&
                 taskDate.month == date.month &&
                 taskDate.day == date.day;
        }
      }
      return false;
    }).toList();
  }

  List<dynamic> _getTasksForMonth(List<dynamic> tasks, DateTime month) {
    return tasks.where((task) {
      final datalimited = task['datalimited'];
      if (datalimited != null) {
        final taskDate = _parseDate(datalimited);
        if (taskDate != null) {
          return taskDate.year == month.year && 
                 taskDate.month == month.month;
        }
      }
      return false;
    }).toList();
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non définie';
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDayDate(DateTime date) {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
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
          return AlertDialog(
            title: const Text(
              'Supprimer la tâche',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('Cette action est irréversible. Êtes-vous sûr de vouloir supprimer cette tâche ?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              TextButton(
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToTaskDetail(BuildContext context, dynamic task, Function? refetch) {
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
        final tasksForDate = _getTasksForDate(tasks, _selectedDate);
        final tasksForMonth = _getTasksForMonth(tasks, _selectedDate);

        return Container(
          color: Colors.grey.shade50,
          child: SafeArea(
            child: Column(
              children: [
                // En-tête du calendrier - DESIGN PROFESSIONNEL
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                  child: Column(
                    children: [
                      // Header avec titre et navigation
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.chevron_left,
                                  size: 24,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month - 1,
                                    _selectedDate.day,
                                  );
                                });
                              },
                            ),
                            Column(
                              children: [
                                Text(
                                  _getMonthYearText(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDayDate(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 24,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month + 1,
                                    _selectedDate.day,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Calendrier amélioré
                      _buildCalendar(tasksForMonth),
                      const SizedBox(height: 20),
                      // Légende des priorités
                      _buildPriorityLegend(),
                    ],
                  ),
                ),

                // Section des tâches
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        // Header des tâches
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tâches du jour',
                                style: TextStyle(
                                  fontSize: 18,
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
                                  '${tasksForDate.length} tâche${tasksForDate.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Liste des tâches
                        Expanded(
                          child: tasksForDate.isEmpty
                              ? Center(
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
                                            Icons.calendar_today_outlined,
                                            size: 60,
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          'Aucune tâche pour cette date',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _formatDate(_selectedDate),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          'Ajoutez des tâches ou sélectionnez une autre date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
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
                                      color: const Color(0xFF6366F1),
                                      onRefresh: () async {
                                        if (refetch != null) await refetch();
                                      },
                                      child: ListView.separated(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                        itemCount: tasksForDate.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final task = tasksForDate[index];
                                          final isCompleted = task['completed'] ?? false;
                                          final priority = task['priority'] ?? 'MEDIUM';

                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.03),
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
                                                  _navigateToTaskDetail(context, task, refetch);
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: Row(
                                                    children: [
                                                      // Checkbox amélioré
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
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment.start,
                                                              children: [
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(
                                                                        task['title'] ?? 'Sans titre',
                                                                        style: TextStyle(
                                                                          fontSize: 16,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          decoration:
                                                                              isCompleted
                                                                                  ? TextDecoration
                                                                                      .lineThrough
                                                                                  : TextDecoration
                                                                                      .none,
                                                                          color: isCompleted
                                                                              ? Colors.grey
                                                                                  .shade400
                                                                              : Colors.black,
                                                                        ),
                                                                        maxLines: 2,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                      if (task['decription'] !=
                                                                              null &&
                                                                          task['decription']
                                                                              .toString()
                                                                              .isNotEmpty)
                                                                        Padding(
                                                                          padding:
                                                                              const EdgeInsets.only(
                                                                                  top: 6),
                                                                          child: Text(
                                                                            task['decription'],
                                                                            style: TextStyle(
                                                                              fontSize: 13,
                                                                              color: isCompleted
                                                                                  ? Colors.grey
                                                                                      .shade400
                                                                                  : Colors.grey
                                                                                      .shade600,
                                                                              height: 1.4,
                                                                            ),
                                                                            maxLines: 2,
                                                                            overflow: TextOverflow
                                                                                .ellipsis,
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 12),
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                    horizontal: 10,
                                                                    vertical: 6,
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    color: _getPriorityBackgroundColor(
                                                                        priority),
                                                                    borderRadius:
                                                                        BorderRadius.circular(12),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize.min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons.circle,
                                                                        size: 8,
                                                                        color:
                                                                            _getPriorityColor(
                                                                                priority),
                                                                      ),
                                                                      const SizedBox(width: 6),
                                                                      Text(
                                                                        _getPriorityLabel(priority)
                                                                            .split(' ')[0],
                                                                        style: TextStyle(
                                                                          fontSize: 12,
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                          color: _getPriorityColor(
                                                                              priority),
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
                                                                  _formatDate(_parseDate(
                                                                      task['datalimited'])),
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
                                                                    _navigateToTaskDetail(
                                                                        context, task, refetch);
                                                                  },
                                                                  padding: EdgeInsets.zero,
                                                                  constraints:
                                                                      const BoxConstraints(),
                                                                ),
                                                                const SizedBox(width: 8),
                                                                IconButton(
                                                                  icon: Icon(
                                                                    Icons.delete_outline,
                                                                    size: 18,
                                                                    color: Colors.red.shade400,
                                                                  ),
                                                                  onPressed: () {
                                                                    _showDeleteDialog(
                                                                        context, task['id'], refetch);
                                                                  },
                                                                  padding: EdgeInsets.zero,
                                                                  constraints:
                                                                      const BoxConstraints(),
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMonthYearText(DateTime date) {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildCalendar(List<dynamic> tasksForMonth) {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Jours de la semaine - design amélioré
          Row(
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          // Grille du calendrier améliorée
          ..._buildCalendarRows(daysInMonth, firstWeekday, tasksForMonth),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarRows(
      int daysInMonth, int firstWeekday, List<dynamic> tasksForMonth) {
    final rows = <Widget>[];
    final weeks = ((daysInMonth + firstWeekday - 1) / 7).ceil();

    for (int week = 0; week < weeks; week++) {
      final rowChildren = <Widget>[];

      for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
        final dayIndex = week * 7 + dayOfWeek - firstWeekday + 2;

        if (dayIndex < 1 || dayIndex > daysInMonth) {
          rowChildren.add(const Expanded(child: SizedBox()));
        } else {
          final date = DateTime(_selectedDate.year, _selectedDate.month, dayIndex);
          rowChildren.add(_buildCalendarDay(date, tasksForMonth));
        }
      }

      rows.add(Row(children: rowChildren));
      if (week < weeks - 1) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return rows;
  }

  Widget _buildCalendarDay(DateTime date, List<dynamic> tasksForMonth) {
    final isSelected = isSameDay(_selectedDate, date);
    final isToday = isSameDay(date, DateTime.now());
    final dayTasks = _getTasksForDay(date, tasksForMonth);
    final hasTasks = dayTasks.isNotEmpty;
    final priorityColors = _getPriorityColors(dayTasks);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = date;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(2),
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? const Color(0xFF6366F1)
                              : Colors.black,
                    ),
                  ),
                  // Points de priorité améliorés
                  if (hasTasks && priorityColors.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: priorityColors.take(3).map((color) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
              if (isToday && !isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<dynamic> _getTasksForDay(DateTime date, List<dynamic> tasksForMonth) {
    return tasksForMonth.where((task) {
      final datalimited = task['datalimited'];
      if (datalimited != null) {
        final taskDate = _parseDate(datalimited);
        if (taskDate != null) {
          return taskDate.year == date.year &&
              taskDate.month == date.month &&
              taskDate.day == date.day;
        }
      }
      return false;
    }).toList();
  }

  List<Color> _getPriorityColors(List<dynamic> tasks) {
    final colors = <Color>[];
    for (var task in tasks) {
      final priority = task['priority'] ?? 'MEDIUM';
      colors.add(_getPriorityColor(priority));
    }
    colors.sort((a, b) {
      final priorityA = _getPriorityFromColor(a);
      final priorityB = _getPriorityFromColor(b);
      return priorityA.compareTo(priorityB);
    });
    return colors;
  }

  int _getPriorityFromColor(Color color) {
    if (color == const Color(0xFFFF4757)) return 1;
    if (color == const Color(0xFFFFA502)) return 2;
    if (color == const Color(0xFF2ED573)) return 3;
    return 4;
  }

  Widget _buildPriorityLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(const Color(0xFFFF4757), 'Haute'),
        const SizedBox(width: 24),
        _buildLegendItem(const Color(0xFFFFA502), 'Moyenne'),
        const SizedBox(width: 24),
        _buildLegendItem(const Color(0xFF2ED573), 'Basse'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}