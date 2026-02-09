import 'package:flutter/material.dart';

class HomecontrolScreen extends StatefulWidget {
  const HomecontrolScreen({super.key});

  @override
  State<HomecontrolScreen> createState() => _HomecontrolScreenState();
}

class _HomecontrolScreenState extends State<HomecontrolScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Homecontrol Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}