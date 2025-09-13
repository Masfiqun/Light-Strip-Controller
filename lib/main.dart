import 'package:flutter/material.dart';
import 'package:light_strip/homepage.dart';


void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    title: 'LightStrip Controller',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.blue),
    home: HomePage(),
    );
  }
}