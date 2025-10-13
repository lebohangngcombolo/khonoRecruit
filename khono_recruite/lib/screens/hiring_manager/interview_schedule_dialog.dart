import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class InterviewScheduleDialog extends StatefulWidget {
  final String token;
  final int? candidateId;

  const InterviewScheduleDialog({super.key, required this.token, this.candidateId});

  @override
  State<InterviewScheduleDialog> createState() => _InterviewScheduleDialogState();
}

class _InterviewScheduleDialogState extends State<InterviewScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _dateTime;
  final _locationController = TextEditingController();
  bool _isPicking = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schedule Interview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDateTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date & Time', border: OutlineInputBorder()),
                      child: Text(
                        _dateTime != null ? _dateTime!.toLocal().toString() : 'Pick date and time',
                        style: TextStyle(color: _dateTime != null ? AppColors.textDark : AppColors.textGrey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, foregroundColor: AppColors.primaryWhite),
                  child: const Text('Schedule'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    if (_isPicking) return;
    _isPicking = true;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) { _isPicking = false; return; }
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) { _isPicking = false; return; }
    setState(() => _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
    _isPicking = false;
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _dateTime == null) return;
    Navigator.pop(context, {
      'candidate_id': widget.candidateId,
      'scheduled_time': _dateTime!.toIso8601String(),
      'location': _locationController.text.trim(),
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
} 