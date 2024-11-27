import 'package:flutter/material.dart';

class DatePickerPage extends StatefulWidget {
  @override
  State<DatePickerPage> createState() => _DatePickerPageState();
}

class _DatePickerPageState extends State<DatePickerPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Выбор даты'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Дата рождения',
                hintText: 'Выберите дату',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2101),
                );
                if (selectedDate != null) {
                  setState(() {
                    _controller.text = "${selectedDate.toLocal()}".split(' ')[0];
                  });
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('Дата выбрана: ${_controller.text}');
                if (_controller.text != "") {
                  Navigator.pop(context, _controller.text);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text('Подтвердить'),
            ),
          ],
        ),
      ),
    );
  }
}
