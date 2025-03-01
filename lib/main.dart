import 'package:flutter/material.dart';
import 'package:online_pdf_reader_app/views/homeView.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Online PDF Reader',
      debugShowCheckedModeBanner: false,
      home: HomeView(),
    );
  }
}

