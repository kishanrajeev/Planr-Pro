import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import 'drawer.dart';
import 'page1.dart';
import 'page2.dart';
import 'page3.dart';
import 'photo_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<File> _photos = [];

  void _takePhoto() async {
    final image = await ImagePicker().getImage(source: ImageSource.camera);
    if (image == null) return; // User cancelled taking a photo
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime
        .now()
        .millisecondsSinceEpoch}.jpg';
    final file = await File(image.path).copy('${directory.path}/$fileName');
    final prefs = await SharedPreferences.getInstance();
    final photoPaths = prefs.getStringList('photos') ?? [];
    photoPaths.add(file.path);
    await prefs.setStringList('photos', photoPaths);
    setState(() {
      _photos.add(file);
    });
  }


  void _deletePhoto(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final photoPaths = prefs.getStringList('photos') ?? [];
    await File(photoPaths[index]).delete();
    photoPaths.removeAt(index);
    await prefs.setStringList('photos', photoPaths);
    setState(() {
      _photos.removeAt(index);
    });
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (BuildContext context,
          AsyncSnapshot<SharedPreferences> snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        final prefs = snapshot.data!;
        final photoPaths = prefs.getStringList('photos') ?? [];
        _photos = photoPaths.map((path) => File(path)).toList();
        return MaterialApp(
          home: DefaultTabController(
            length: 4,
            child: Scaffold(
              appBar: AppBar(
                leading: Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      icon: const Icon(Icons.settings),
                    );
                  },
                ),
                bottom: TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.assignment), text: 'Tasks'),
                    Tab(icon: Icon(Icons.quiz), text: 'Quizzes'),
                    Tab(icon: Icon(Icons.school), text: 'Other'),
                    Tab(icon: Icon(Icons.image), text: 'Gallery'),
                  ],
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.camera_alt_rounded),
                    onPressed: _takePhoto,
                  )
                ],
                backgroundColor: Colors.blueGrey[800],
                title: Container(
                  padding: EdgeInsets.only(),
                  child: Center(
                    child: Text('Planr Pro'),
                  ),
                ),
              ),
              drawer: Drawer(
                width: 250,
                backgroundColor: Colors.blueGrey[800],
                child: DrawerContent(),
              ),
              body: Builder(
                builder: (BuildContext context) {
                  return Container(
                    child: Container(
                      height: 1000,
                      child: TabBarView(
                        children: [
                          Container(
                            child: Container(
                              height: 1000,
                              child: Page1(),
                            ),
                          ),
                          Container(
                            child: Container(
                              height: 1000,
                              child: Page2(),
                            ),
                          ),
                          Container(
                            child: Container(
                              height: 1000,
                              child: Page3(),
                            ),
                          ),
                          Container(
                            color: Colors.white, // Set the background color to white
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                              ),
                              itemCount: _photos.length,
                              itemBuilder: (BuildContext context, int index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PhotoPage(_photos[index]),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: FileImage(_photos[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: TextButton(
                                        onPressed: () {
                                          _deletePhoto(index);
                                        },
                                        child: Icon(Icons.delete, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        ],
                      ),)
                    ,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
