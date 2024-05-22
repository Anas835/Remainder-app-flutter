import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(ReminderApp());
}

class ReminderApp extends StatefulWidget {
  @override
  _ReminderAppState createState() => _ReminderAppState();
}

class _ReminderAppState extends State<ReminderApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder App',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: ReminderHomePage(
        isDarkMode: _isDarkMode,
        onThemeChanged: (bool isDark) {
          setState(() {
            _isDarkMode = isDark;
          });
        },
      ),
    );
  }
}

class ReminderHomePage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  ReminderHomePage({required this.isDarkMode, required this.onThemeChanged});

  @override
  _ReminderHomePageState createState() => _ReminderHomePageState();
}

class _ReminderHomePageState extends State<ReminderHomePage> with SingleTickerProviderStateMixin {
  String _selectedDay = 'Monday';
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedActivity = 'Wake up';
  List<Map<String, dynamic>> _reminders = [];
  late AnimationController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<String> daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  List<String> activities = [
    'Wake up', 'Go to gym', 'Breakfast', 'Meetings', 'Lunch',
    'Quick nap', 'Go to library', 'Dinner', 'Go to sleep'
  ];

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(minutes: 1), (timer) {
      _checkReminders();
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _checkReminders() {
    final now = TimeOfDay.now();
    final today = DateTime.now().weekday;
    final currentDay = daysOfWeek[today - 1];

    for (var reminder in _reminders) {
      if (reminder['day'] == currentDay &&
          reminder['time'].hour == now.hour &&
          reminder['time'].minute == now.minute) {
        _showReminderDialog(reminder['activity']);
      }
    }
  }

  void _showReminderDialog(String activity) {
    _playReminderSound();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reminder'),
          content: Text('It\'s time to $activity'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _playReminderSound() async {
    await _audioPlayer.play('assets/sound/notification_sound.mp3', isLocal: true);
  }

  void _addReminder() {
    setState(() {
      _reminders.add({
        'day': _selectedDay,
        'time': _selectedTime,
        'activity': _selectedActivity
      });
    });

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for $_selectedActivity')),
    );

    // Start the animation
    _controller.forward(from: 0.0);
  }

  void _editReminder(int index) {
    setState(() {
      _selectedDay = _reminders[index]['day'];
      _selectedTime = _reminders[index]['time'];
      _selectedActivity = _reminders[index]['activity'];
    });

    // Show the dialog to edit the reminder
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDay,
                onChanged: (String? newValue) {
                  setState(() {
                    if (newValue != null) {
                      _selectedDay = newValue;
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Select Day',
                  border: OutlineInputBorder(),
                ),
                items: daysOfWeek.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today),
                        SizedBox(width: 10),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) {
                    setState(() {
                      _selectedTime = time;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Select Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTime.format(context),
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.access_time),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedActivity,
                onChanged: (String? newValue) {
                  setState(() {
                    if (newValue != null) {
                      _selectedActivity = newValue;
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Select Activity',
                  border: OutlineInputBorder(),
                ),
                items: activities.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(Icons.event),
                        SizedBox(width: 10),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _reminders[index] = {
                    'day': _selectedDay,
                    'time': _selectedTime,
                    'activity': _selectedActivity
                  };
                });
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder deleted')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminder App'),
        actions: [
          Switch(
            value: widget.isDarkMode,
            onChanged: widget.onThemeChanged,
            activeColor: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: _selectedDay,
              onChanged: (String? newValue) {
                setState(() {
                  if (newValue != null) {
                    _selectedDay = newValue;
                  }
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Day',
                border: OutlineInputBorder(),
              ),
              items: daysOfWeek.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 10),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select Time',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTime.format(context),
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.access_time),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedActivity,
              onChanged: (String? newValue) {
                setState(() {
                  if (newValue != null) {
                    _selectedActivity = newValue;
                  }
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Activity',
                border: OutlineInputBorder(),
              ),
              items: activities.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(Icons.event),
                      SizedBox(width: 10),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _addReminder,
              child: Text('Set Reminder'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeInOut,
                ),
                child: ListView.builder(
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = _reminders[index];
                    return ListTile(
                      leading: Icon(Icons.notifications),
                      title: Text('${reminder['activity']}'),
                      subtitle: Text(
                          '${reminder['day']} at ${reminder['time'].format(context)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editReminder(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteReminder(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
