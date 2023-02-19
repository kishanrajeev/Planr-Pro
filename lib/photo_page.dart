import 'dart:io';

import 'package:flutter/material.dart';

class PhotoPage extends StatelessWidget {
  final File photo;

  const PhotoPage(this.photo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[800],
        title: Text('Your Image Task:'),
      ),
      body: Center(
        child: Image.file(photo),
      ),
    );
  }
}
