import 'package:flutter/material.dart';

class Vaultscreen extends StatefulWidget {
  const Vaultscreen({super.key});

  @override
  State<Vaultscreen> createState() => _VaultscreenState();
}

class _VaultscreenState extends State<Vaultscreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Vault Screen'),
      ),
    );
  }
}