import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/task_queries.dart';

class AddTaskForm extends StatefulWidget {
  final Function() onTaskCreated;
  const AddTaskForm({super.key, required this.onTaskCreated});

  @override
  State<AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<AddTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'MEDIUM';
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nouvelle tâche',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
            TextFormField(
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
                  initialDate: DateTime.now(),
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
            const SizedBox(height: 24),
            Mutation(
              options: MutationOptions(
                document: gql(TaskQueries.createTask),
                onCompleted: (data) {
                  if (data != null) {
                    widget.onTaskCreated();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tâche créée avec succès !')),
                    );
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
                            : 'Erreur lors de la création',
                      ),
                    ),
                  );
                  setState(() {
                    _isLoading = false;
                  });
                },
              ),
              builder: (runMutation, result) {
                return ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            runMutation({
                              'title': _titleController.text.trim(),
                              'decription': _descriptionController.text.trim(),
                              'priority': _priority,
                              'datalimited': _dueDate != null
                                  ? _dueDate!.toIso8601String().split('T')[0]
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
                      : const Text('Créer la tâche'),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

