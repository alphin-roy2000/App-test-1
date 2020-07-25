
import 'package:Capturoca/pages/HomePage.dart';


import 'package:flutter/material.dart';

void main()
{
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capturoca',
      debugShowCheckedModeBanner: false,
      theme: ThemeData
      (
        scaffoldBackgroundColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        primarySwatch: Colors.red,
        accentColor: Colors.indigoAccent,
        cardColor: Colors.white70,
        
      ),
      home:HomePage(),
    );
  }

  
  
}