import 'package:flutter/material.dart';

class TrustMeScreen extends StatefulWidget {
  const TrustMeScreen({super.key});

  @override
  State<TrustMeScreen> createState() => _TrustMeScreenState();
}

class _TrustMeScreenState extends State<TrustMeScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Trust Me Screen'),
      ),
    );
  }
}