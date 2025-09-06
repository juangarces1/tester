import 'package:flutter/material.dart';

class MyDatePickerDialog extends StatelessWidget {
  final Function(DateTime) onDateSelected;

  const MyDatePickerDialog({super.key, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccione una fecha'),
      content: SizedBox(
        // Tamaño del DatePicker
        height: 200,
        child: Column(
          children: <Widget>[
            Expanded(
              child: _DatePicker(onDateSelected: onDateSelected),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePicker extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const _DatePicker({required this.onDateSelected});

  @override
  _DatePickerState createState() => _DatePickerState();
}

class _DatePickerState extends State<_DatePicker> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return CalendarDatePicker(
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
      onDateChanged: (newDate) {
        setState(() {
          selectedDate = newDate;
        });
        widget.onDateSelected(newDate);
      },
    );
  }
}
