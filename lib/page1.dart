import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';




class Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class Assignment {
  String id;
  String title;
  DateTime date;
  TimeOfDay time;
  DateTime selectedDate; // New field
  TimeOfDay selectedTime; // New field

  Assignment({
    required this.title,
    required this.date,
    required this.time,
    required this.selectedDate,
    required this.selectedTime,
    String? id,
  }) : this.id = id ?? Uuid().v4();
}


class ClassDetails extends StatefulWidget {
  bool _pressed = false;
  final String className;
  final GlobalKey<_ClassDetailsState> key = GlobalKey();

  ClassDetails({required Key key, this.className = "Class Name"})
      : super(key: key);

  @override
  _ClassDetailsState createState() => _ClassDetailsState();
}

class _ClassDetailsState extends State<ClassDetails> {
  final _classController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _classController.text = widget.className;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: TextField(
          controller: _classController,
          decoration: InputDecoration(hintText: 'Enter Class Details'),
        ),
      ),
    );
  }
}

class _HomePageState extends State<HomePage> {
  List<Assignment> _assignments = [];
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now(); // Added selected time
  final _assignmentController = TextEditingController();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadAssignments();
    initializeNotifications();
  }

  void initializeNotifications() async {
    var initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize time zone
    tz.initializeTimeZones();
  }

  Future<void> scheduleNotification(
      String id,
      String title,
      DateTime date,
      TimeOfDay time,
      ) async {
    print("Scheduling notification for: $title at $date $time");

    DateTime scheduledDateTime = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Calculate the current date and time in the user's local timezone
    DateTime now = tz.TZDateTime.now(tz.local);

    // Check if the scheduled date is before the current date
    if (scheduledDateTime.isBefore(DateTime(now.year, now.month, now.day))) {
      scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
    }

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      id.toString(),
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Convert selected date/time to local timezone

    await flutterLocalNotificationsPlugin.zonedSchedule(
      hashValues(id, scheduledDateTime).hashCode,
      // Generate a unique notification ID
      'Assignment Reminder',
      title,
      tz.TZDateTime(
        tz.local,
        scheduledDateTime.year,
        scheduledDateTime.month,
        scheduledDateTime.day,
        scheduledDateTime.hour,
        scheduledDateTime.minute,
      ),
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation
          .absoluteTime,
      androidAllowWhileIdle: true,
    );
  }




  void _shuffleAssignments() {
    setState(() {
      _assignments.shuffle();
    });
    _saveAssignments();
  }

  void _addAssignment() async {
    if (_assignments.length < 100) {
      DateTime? selectedDate = await _selectDate(context);
      if (selectedDate != null) {
        TimeOfDay? selectedTime = await _selectTime(context);
        if (selectedTime != null) {
          setState(() {
            Assignment newAssignment = Assignment(
              title: _assignmentController.text,
              date: selectedDate,
              time: selectedTime,
              selectedDate: selectedDate, // Store selected date
              selectedTime: selectedTime, // Store selected time
            );
            int newIndex = _assignments.length;
            _assignments.add(newAssignment);
            _saveAssignments();
            scheduleNotification(
              newAssignment.id,
              newAssignment.title,
              newAssignment.selectedDate, // Use selected date
              newAssignment.selectedTime, // Use selected time
            );
          });

          _assignmentController.clear();
        }
      }
    }
  }





  void _renameAssignment(int index) async {
    final _assignmentController = TextEditingController();

    String newName = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rename Assignment"),
        content: TextField(
          controller: _assignmentController,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter New Name'),
        ),
        actions: [
          TextButton(
            child: Text("Rename"),
            onPressed: () =>
                Navigator.of(context).pop(_assignmentController.text),
          ),
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ],
      ),
    );

    if (newName != null) {
      setState(() {
        _assignments[index].title = newName;
      });
      _saveAssignments();

      // Reschedule notification with updated assignment details
      scheduleNotification(
        _assignments[index].id,
        _assignments[index].title,
        _assignments[index].selectedDate, // Use selected date
        _assignments[index].selectedTime, // Use selected time
      );
    }
  }



  void _deleteAssignment(int index) {
    setState(() {
      _assignments.removeAt(index);
    });
    _saveAssignments();
  }

  void _saveAssignments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedAssignments = _assignments
        .map((assignment) =>
    '${assignment.id},${assignment.title},${assignment.date.millisecondsSinceEpoch},${assignment.time.hour},${assignment.time.minute},${assignment.selectedDate.millisecondsSinceEpoch},${assignment.selectedTime.hour},${assignment.selectedTime.minute}')
        .toList();
    prefs.setStringList("assignments", savedAssignments);
  }


  void _loadAssignments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedAssignments = prefs.getStringList("assignments") ?? [];

    setState(() {
      _assignments = savedAssignments
          .map((savedAssignment) {
        List<String> parts = savedAssignment.split(',');
        return Assignment(
          id: parts[0],
          title: parts[1],
          date: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])),
          time: TimeOfDay(hour: int.parse(parts[3]), minute: int.parse(parts[4])),
          selectedDate: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[5])),
          selectedTime: TimeOfDay(hour: int.parse(parts[6]), minute: int.parse(parts[7])),
        );
      })
          .toList();
    });
  }


  Future<DateTime?> _selectDate(BuildContext context) async {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime dt = tz.TZDateTime(tz.local, now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dt,
      firstDate: dt,
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != dt) {
      setState(() {
        _selectedDate = picked;
      });
    }

    return picked;
  }

  Future<TimeOfDay?> _selectTime(BuildContext context) async {

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(tz.TZDateTime.now(tz.local)),
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }

    return picked;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(20),
            child: TextField(
              controller: _assignmentController,
              decoration: InputDecoration(hintText: 'Enter Name of Assignment'),
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  child: Text(
                    "Shuffle List".toUpperCase(),
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.all(15),
                    ),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.blueGrey),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: Colors.blueGrey),
                      ),
                    ),
                  ),
                  onPressed: _shuffleAssignments,
                ),
                SizedBox(width: 20),
                TextButton(
                  child: Text(
                    "Add Assignment".toUpperCase(),
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.all(15),
                    ),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.blueGrey),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: Colors.blueGrey),
                      ),
                    ),
                  ),
                  onPressed: _addAssignment,
                ),
                SizedBox(width: 20),

              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemCount: _assignments.length,
              itemBuilder: (context, index) {
                return ListTile(
                  key: Key('$index'), // Add a key to identify the ListTile
                  title: Text(_assignments[index].title),
                  subtitle: Text(_assignments[index].date.toString()),
                  leading: Icon(Icons.assignment),
                  onTap: () {},
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _deleteAssignment(index);
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _renameAssignment(index);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications_active),
                        onPressed: () async {
                          DateTime? selectedDate = await _selectDate(context);
                          if (selectedDate != null) {
                            TimeOfDay? selectedTime = await _selectTime(context);
                            if (selectedTime != null) {
                              scheduleNotification(
                                Uuid().v4(), // Generate a new UUID for each notification
                                "Assignment Title", // Use an appropriate title here
                                selectedDate,
                                selectedTime,
                              );
                            }
                          }
                        },
                      ),



                    ],
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _assignments.removeAt(oldIndex);
                  _assignments.insert(newIndex, item);
                });
              },
            ),
          ),

        ],
      ),
    );
  }
}
