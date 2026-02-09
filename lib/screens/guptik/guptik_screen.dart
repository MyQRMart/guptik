import 'package:flutter/material.dart';

class GuptikScreen extends StatefulWidget {
  const GuptikScreen({super.key});

  @override
  State<GuptikScreen> createState() => _GuptikScreenState();
}

class _GuptikScreenState extends State<GuptikScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Guptik Screen'),
      ),
    );
  }
}