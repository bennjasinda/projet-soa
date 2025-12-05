import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/task_queries.dart';

class EditTaskScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onTaskUpdated;

  const EditTaskScreen({
    super.key,
    required this.task,
    this.onTaskUpdated,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _priority;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task['title'] ?? '');
    _descriptionController = TextEditingController(
      text: widget.task['decription'] ?? '',
    );
    _priority = widget.task['priority'] ?? 'MEDIUM';
    
    // Parser la date limite si elle existe
    final datalimited = widget.task['datalimited'];
    if (datalimited != null) {
      try {
        final dateStr = datalimited.toString().split('T')[0];
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          _dueDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (e) {
        // Ignorer l'erreur de parsing
      }
    }
    
    // Parser le temps limite si il existe
    final timelimited = widget.task['timelimited'];
    if (timelimited != null && timelimited.toString().isNotEmpty) {
      try {
        final parts = timelimited.toString().split(':');
        if (parts.length == 2) {
          _dueTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (e) {
        // Ignorer l'erreur de parsing
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la tâche'),
      ),
      body: Mutation(
        options: MutationOptions(
          document: gql(TaskQueries.updateTask),
          onCompleted: (data) {
            if (data != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tâche mise à jour avec succès !')),
              );
              if (widget.onTaskUpdated != null) {
                widget.onTaskUpdated!();
              }
              Navigator.pop(context);
            }
            setState(() {
              _isLoading = false;
            });
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  error?.graphqlErrors.isNotEmpty == true
                      ? error!.graphqlErrors.first.message
                      : 'Erreur lors de la mise à jour',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
          },
        ),
        builder: (runMutation, result) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre *',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le titre est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priorité',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'HIGH', child: Text('Haute')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Moyenne')),
                      DropdownMenuItem(value: 'LOW', child: Text('Basse')),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) => setState(() => _priority = value!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date limite (optionnel)',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: const OutlineInputBorder(),
                            suffixText: _dueDate != null
                                ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                : null,
                          ),
                          enabled: !_isLoading,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _dueDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setState(() {
                                _dueDate = date;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Heure (optionnel)',
                            prefixIcon: const Icon(Icons.access_time),
                            border: const OutlineInputBorder(),
                            suffixText: _dueTime != null
                                ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
                                : null,
                          ),
                          enabled: !_isLoading && _dueDate != null,
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _dueTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                _dueTime = time;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isLoading = true;
                              });
                              runMutation({
                                'id': widget.task['id'],
                                'title': _titleController.text.trim(),
                                'decription': _descriptionController.text.trim(),
                                'priority': _priority,
                                'datalimited': _dueDate != null
                                    ? _dueDate!.toIso8601String().split('T')[0]
                                    : null,
                                'timelimited': _dueTime != null
                                    ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
                                    : null,
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

