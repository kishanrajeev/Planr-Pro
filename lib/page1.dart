import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Date Picker code
//  onTap: () async {
//                     DateTime? date = await showDatePicker(
//                       context: context,
//                       initialDate: DateTime.now(),
//                       firstDate: DateTime.now(),
//                       lastDate: DateTime(2050),
//                       currentDate: DateTime.now(),
//                       initialEntryMode: DatePickerEntryMode.calendar,
//                       initialDatePickerMode: DatePickerMode.day,
//                       builder: (context, child) {
//                         return Theme(
//                           data: Theme.of(context).copyWith(
//                             colorScheme: ColorScheme.fromSwatch(
//                               primarySwatch: Colors.blueGrey,
//                               accentColor: Colors.black,
//                               backgroundColor: Colors.lightBlue,
//                               cardColor: Colors.white,
//                             ),
//                           ),
//                           child: child!,
//                         );
//                       },
//                     );
//                     if (date != null) {
//                       setState(() {
//                         _selectedDate = date;
//                       });
//                     }
//                   },//


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
class Class {
  String title;
  DateTime date;
  Class({required this.title, required this.date});
}

List<Class> _classes1 = [];


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
  List<String> _classes1 = [];
  DateTime _selectedDate = DateTime.now();
  final _classController = TextEditingController();

  void _shuffleClasses() {
    setState(() {
      _classes1.shuffle();
    });
    _saveclasses1();
  }

  void _addClass() {
    if (_classes1.length < 100) {
      setState(() {
        _classes1.add(_classController.text);
      });
      _saveclasses1();
    }
    _classController.clear();


  }

  void _renameClass(int index) async {
    final _classController = TextEditingController();

    String newName = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rename Class"),
        content: TextField(
          controller: _classController,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter New Name'),
        ),
        actions: [
          TextButton(
            child: Text("Rename"),
            onPressed: () => Navigator.of(context).pop(_classController.text),
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
        _classes1[index] = newName;
      });
      _saveclasses1();
    }
  }

  void _deleteClass(int index) {
    setState(() {
      _classes1.removeAt(index);
    });
    _saveclasses1();
  }

  void _saveclasses1() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList("classes1", _classes1);
  }

  void _loadclasses1() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedclasses1 = prefs.getStringList("classes1") ?? [];
    setState(() {
      _classes1 = savedclasses1;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadclasses1();
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
              controller: _classController,
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
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                          side: BorderSide(color: Colors.blueGrey),
                        ),
                      ),
                    ),
                    onPressed: (_shuffleClasses)
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
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                          side: BorderSide(color: Colors.blueGrey),
                        ),
                      ),
                    ),
                    onPressed: (_addClass)
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemCount: _classes1.length,
              itemBuilder: (context, index) {
                return ListTile(
                  key: Key('$index'), // Add a key to identify the ListTile
                  title: Text(_classes1[index]),
                  leading: Icon(Icons.book),
                  onTap: () {},
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _deleteClass(index);
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _renameClass(index);
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
                  final item = _classes1.removeAt(oldIndex);
                  _classes1.insert(newIndex, item);
                });
              },
            ),
          ),

        ],
      ),
    );
  }
}
