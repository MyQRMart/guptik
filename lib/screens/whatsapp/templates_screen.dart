import 'package:flutter/material.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text(
          'Templates',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: const Center(
        child: Text('Templates screen'),
      ),
    );
  }
}