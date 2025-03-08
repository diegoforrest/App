import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int? _selectedDay;
  TimeOfDay? _selectedTime;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> _scheduledNotifications = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestPermissions();
    _loadSavedNotifications();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await _createNotificationChannel();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'paddy_reminder',
      'Paddy Reminder',
      description: 'Channel for Paddy Reminder notifications',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _scheduleWeeklyNotification() async {
    if (_selectedDay == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a day and time')),
      );
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final int daysToAdd = (_selectedDay! - now.weekday + 7) % 7;

    final nextNotification = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day +
          (daysToAdd == 0 &&
              (_selectedTime!.hour < now.hour ||
                  (_selectedTime!.hour == now.hour &&
                      _selectedTime!.minute <= now.minute))
              ? 7
              : daysToAdd),
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final androidDetails = AndroidNotificationDetails(
      'paddy_reminder',
      'Paddy Reminder',
      channelDescription: 'Channel for Paddy Reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      _nameController.text.isNotEmpty ? _nameController.text : 'Paddy Reminder',
      _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : 'Reminder notification',
      nextNotification,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    _saveNotification(id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weekly notification scheduled')),
    );
  }

  Future<void> _saveNotification(int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final Map<String, dynamic> newNotification = {
      'id': id,
      'title': _nameController.text.isNotEmpty ? _nameController.text : 'Paddy Reminder',
      'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : 'Reminder notification',
      'day': days[_selectedDay! - 1],  // Convert day index to string
      'time': _selectedTime!.format(context),
    };

    setState(() {
      _scheduledNotifications.add(newNotification);
    });

    await prefs.setString('notifications', jsonEncode(_scheduledNotifications));
  }

  void _updateNotification(int index) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    setState(() {
      _scheduledNotifications[index] = {
        'id': _scheduledNotifications[index]['id'],
        'title': _nameController.text,
        'description': _descriptionController.text,
        'day': days[_selectedDay! - 1],
        'time': _selectedTime!.format(context),
      };
    });

    await prefs.setString('notifications', jsonEncode(_scheduledNotifications));
  }


  void _editNotification(BuildContext context, int index) {
    final notif = _scheduledNotifications[index];

    _nameController.text = notif['title'];
    _descriptionController.text = notif['description'];
    _selectedDay = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        .indexOf(notif['day']) + 1;
    _selectedTime = TimeOfDay(
      hour: int.parse(notif['time'].split(":")[0]),
      minute: int.parse(notif['time'].split(":")[1]),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Notification"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              DropdownButton<int>(
                value: _selectedDay,
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedDay = newValue;
                  });
                },
                items: List.generate(7, (index) {
                  return DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][index]),
                  );
                }),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickTime,
                child: Text(_selectedTime == null ? "Select Time" : "Time: ${_selectedTime!.format(context)}"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateNotification(index);
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }



  Future<void> _loadSavedNotifications() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedNotifications = prefs.getString('notifications');

    if (savedNotifications != null) {
      setState(() {
        _scheduledNotifications =
        List<Map<String, dynamic>>.from(jsonDecode(savedNotifications));
      });
    }
  }

  Future<void> _deleteNotification(int id) async {
    setState(() {
      _scheduledNotifications.removeWhere((notif) => notif['id'] == id);
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', jsonEncode(_scheduledNotifications));

    await flutterLocalNotificationsPlugin.cancel(id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Notification', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 20),

            // Day Picker
            DropdownButton<int>(
              hint: const Text("Select a day"),
              value: _selectedDay,
              onChanged: (int? newValue) {
                setState(() {
                  _selectedDay = newValue;
                });
              },
              items: List.generate(7, (index) {
                return DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text(
                    ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][index],
                  ),
                );
              }),
            ),

            const SizedBox(height: 10),

            // Time Picker
            ElevatedButton(
              onPressed: _pickTime,
              child: Text(_selectedTime == null
                  ? "Select Time"
                  : "Time: ${_selectedTime!.format(context)}"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _scheduleWeeklyNotification,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 20),
            const Divider(),

            const Text('Scheduled Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            Expanded(
              child: ListView.builder(
                itemCount: _scheduledNotifications.length,
                itemBuilder: (context, index) {
                  final notif = _scheduledNotifications[index];

                  return ListTile(
                    title: Text(notif['title']),
                    subtitle: Text('${notif['description']}\n${notif['day']}, ${notif['time']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteNotification(notif['id']),
                    ),
                    onTap: () => _editNotification(context, index), // Open edit dialog on tap
                  );
                },

              ),
            ),
          ],
        ),
      ),
    );
  }
}
