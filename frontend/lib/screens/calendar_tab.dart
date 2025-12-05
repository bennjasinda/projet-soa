import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/task_queries.dart';
import 'task_detail_screen.dart';
import 'edit_task_screen.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _selectedDate = DateTime.now();

  List<dynamic> _getTasksForDate(List<dynamic> tasks, DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return tasks.where((task) {
      final datalimited = task['datalimited'];
      
      if (datalimited != null) {
        final taskDate = datalimited.toString().split('T')[0];
        return taskDate == dateStr;
      }
      return false;
    }).toList();
  }

  List<dynamic> _getTasksForMonth(List<dynamic> tasks, DateTime month) {
    return tasks.where((task) {
      final datalimited = task['datalimited'];
      if (datalimited != null) {
        try {
          final taskDate = datalimited.toString().split('T')[0];
          final parts = taskDate.split('-');
          if (parts.length == 3) {
            final taskDateTime = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            return taskDateTime.year == month.year && 
                   taskDateTime.month == month.month;
          }
        } catch (e) {
          return false;
        }
      }
      return false;
    }).toList();
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
        final tasksForDate = _getTasksForDate(tasks, _selectedDate);
        final tasksForMonth = _getTasksForMonth(tasks, _selectedDate);

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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime(
                              _selectedDate.year,
                              _selectedDate.month - 1,
                            );
                          });
                        },
                      ),
                      Text(
                        '${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime(
                              _selectedDate.year,
                              _selectedDate.month + 1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Calendrier simple
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _selectedDate,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDate, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                      });
                    },
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    tasksForMonth: tasksForMonth,
                    selectedDate: _selectedDate,
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasksForDate.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucune tâche pour cette date',
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
                            itemCount: tasksForDate.length,
                            itemBuilder: (context, index) {
                              final task = tasksForDate[index];
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

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Widget calendrier simple
class TableCalendar extends StatelessWidget {
  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime focusedDay;
  final bool Function(DateTime) selectedDayPredicate;
  final void Function(DateTime, DateTime) onDaySelected;
  final CalendarFormat calendarFormat;
  final StartingDayOfWeek startingDayOfWeek;
  final CalendarStyle calendarStyle;
  final List<dynamic> tasksForMonth;
  final DateTime selectedDate;

  const TableCalendar({
    super.key,
    required this.firstDay,
    required this.lastDay,
    required this.focusedDay,
    required this.selectedDayPredicate,
    required this.onDaySelected,
    required this.calendarFormat,
    required this.startingDayOfWeek,
    required this.calendarStyle,
    required this.tasksForMonth,
    required this.selectedDate,
  });

  List<dynamic> _getTasksForDay(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return tasksForMonth.where((task) {
      final datalimited = task['datalimited'];
      if (datalimited != null) {
        final taskDate = datalimited.toString().split('T')[0];
        return taskDate == dateStr;
      }
      return false;
    }).toList();
  }

  Color? _getHighestPriorityColor(List<dynamic> tasks) {
    if (tasks.isEmpty) return null;
    for (var task in tasks) {
      final priority = task['priority'] ?? 'MEDIUM';
      if (priority == 'HIGH') return Colors.red;
    }
    for (var task in tasks) {
      final priority = task['priority'] ?? 'MEDIUM';
      if (priority == 'MEDIUM') return Colors.orange;
    }
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        // Jours de la semaine
        Row(
          children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Grille du calendrier
        ...List.generate(
          ((daysInMonth + firstWeekday - 1) / 7).ceil(),
          (week) {
            return Row(
              children: List.generate(7, (day) {
                final dayIndex = week * 7 + day - firstWeekday + 2;

                if (dayIndex < 1 || dayIndex > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }

                final date = DateTime(focusedDay.year, focusedDay.month, dayIndex);
                final isSelected = selectedDayPredicate(date);
                final isToday = isSameDay(date, DateTime.now());
                final dayTasks = _getTasksForDay(date);
                final hasTasks = dayTasks.isNotEmpty;
                final priorityColor = _getHighestPriorityColor(dayTasks);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDaySelected(date, date),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? calendarStyle.selectedDecoration?.color
                            : isToday
                                ? calendarStyle.todayDecoration?.color
                                : null,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayIndex.toString(),
                            style: TextStyle(
                              color: isSelected || isToday
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (hasTasks && priorityColor != null)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected || isToday
                                    ? Colors.white
                                    : priorityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

enum CalendarFormat { month, week, twoWeeks }
enum StartingDayOfWeek { monday, sunday }

class CalendarStyle {
  final BoxDecoration? todayDecoration;
  final BoxDecoration? selectedDecoration;

  const CalendarStyle({
    this.todayDecoration,
    this.selectedDecoration,
  });
}
