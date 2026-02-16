import 'package:flutter/material.dart';

enum MediaType { photo, video }

class VaultMedia {
  final String id;
  final String url; // URL or Local Path
  final MediaType type;
  final DateTime dateAdded;
  bool isSynced;

  VaultMedia({
    required this.id,
    required this.url,
    required this.type,
    required this.dateAdded,
    this.isSynced = false,
  });
}