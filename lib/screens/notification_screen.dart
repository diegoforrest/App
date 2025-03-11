import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; // Import this at the top

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

    await _saveNotification(id);
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _selectedDay = null; // Reset day selection
      _selectedTime = null; // Reset time selection
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weekly notification scheduled')),
    );
  }

  Future<void> _saveNotification(int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final String newTitle = _nameController.text.isNotEmpty ? _nameController.text : 'Paddy Reminder';

    // Check if a notification with the same title already exists
    final existingIndex = _scheduledNotifications.indexWhere((notif) => notif['title'] == newTitle);

    final Map<String, dynamic> newNotification = {
      'id': id,
      'title': newTitle,
      'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : 'Reminder notification',
      'day': days[_selectedDay! - 1], // Convert day index to string
      'time': _selectedTime!.format(context),
    };

    setState(() {
      if (existingIndex != -1) {
        // If the title already exists, update the existing notification
        _scheduledNotifications[existingIndex] = newNotification;
      } else {
        // Otherwise, add a new notification
        _scheduledNotifications.add(newNotification);
      }
    });

    await prefs.setString('notifications', jsonEncode(_scheduledNotifications));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(existingIndex != -1 ? 'Notification updated' : 'Notification saved')),
    );
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
        title: const Text(
          'Paddy Notification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 15),
            child: TextButton(
              onPressed: _scheduleWeeklyNotification,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Color(0xFFFFFFFF), // Gold-like color
                ),
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green, // Stylish label color
                ),
                filled: true,
                fillColor: Colors.grey[200], // Light background for a soft look
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                  borderSide: BorderSide.none, // No harsh border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green, width: 2), // Highlight on focus
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15), // Spacing inside
                prefixIcon: Icon(Icons.title, color: Colors.green), // Icon for better UX
              ),
            ),

            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              maxLines: 3, // Allows multiline input
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green, // Stylish label color
                ),
                filled: true,
                fillColor: Colors.grey[200], // Light background for a soft look
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                  borderSide: BorderSide.none, // No harsh border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green, width: 2), // Highlight on focus
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15), // Spacing inside
                prefixIcon: Icon(Icons.description, color: Colors.green), // Adds an icon for UX
              ),
            ),
            SizedBox(height: 15),


            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10), // More space on left & right
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Keeps them apart
                children: [
                  // Day Picker (Left)
                  Container(
                    width: 160,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade700, width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        hint: Text(
                          "Select Day",
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                        value: _selectedDay,
                        isExpanded: false,
                        dropdownColor: Colors.white,
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.green.shade700, size: 20),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
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
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  // Time Picker (Right)

                  Container(
                    width: 160,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade700, width: 1.5),
                    ),
                    child: TextButton(
                      onPressed: _pickTime,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedTime == null ? "Select Time" : _selectedTime!.format(context),
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                          Icon(Icons.access_time, color: Colors.green.shade700, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),


            SizedBox(height: 25),

            Align(
              alignment: Alignment.centerLeft, // Aligns text to the left
              child: Text(
                'Alarms',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),



            Expanded(
              child: ListView.builder(
                itemCount: _scheduledNotifications.length,
                itemBuilder: (context, index) {
                  final notif = _scheduledNotifications[index];

                  return Column(
                    children: [
                      // Divider before the first item
                      if (index == 0) Divider(color: Colors.black, thickness: 1),

                      Dismissible(
                        key: Key(notif['id'].toString()), // Unique key for each item
                        direction: DismissDirection.endToStart, // Swipe left to delete
                        background: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade900, Color(0xFFF33930)], // Dark red to bright red
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 8),
                              Text(
                                "Delete",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (direction) {
                          _deleteNotification(notif['id']); // Call delete function
                        },
                        child: GestureDetector(
                          onLongPress: () {
                            // Haptic feedback for better UX
                            HapticFeedback.mediumImpact();

                            // Open edit dialog after 1 second
                            Future.delayed(Duration(seconds: 1), () {
                              _editNotification(context, index);
                            });

                            // Show feedback to user
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Hold to edit...")),
                            );
                          },
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: notif['time'].split(' ')[0], // Extract time
                                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: ' ${notif['time'].split(' ')[1]}', // AM/PM
                                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(notif['day'], style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                                SizedBox(height: 2),
                                Text(notif['description'], style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Divider after each notification
                      Divider(color: Colors.black, thickness: 1),
                    ],
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