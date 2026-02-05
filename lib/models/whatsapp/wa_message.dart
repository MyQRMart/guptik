import 'dart:convert';
import 'package:flutter/foundation.dart';

class Message {
  final String id;
  final String conversationId;
  final String messageId;
  final String content;
  final String messageType;
  final String direction; // 'incoming', 'outgoing', 'ai_outgoing'
  final String? status;
  final DateTime timestamp;
  final DateTime? statusTimestamp;
  final String? templateId;
  final Map<String, dynamic>? mediaInfo;
  final Map<String, dynamic>? rawData;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.messageId,
    required this.content,
    this.messageType = 'text',
    required this.direction,
    this.status,
    required this.timestamp,
    this.statusTimestamp,
    this.templateId,
    this.mediaInfo,
    this.rawData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      messageId: json['message_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      direction: json['direction']?.toString() ?? '',
      status: json['status']?.toString(),
      
      // FIXED: Proper timestamp parsing
      timestamp: _parseDateTime(json['timestamp']),
      
      statusTimestamp: json['status_timestamp'] != null
          ? _parseDateTime(json['status_timestamp'])
          : null,
      templateId: json['template_id']?.toString(),
      
      // Use the helper method
      mediaInfo: _parseJsonField(json['media_info']),
      rawData: _parseJsonField(json['raw_data']),
      
      // FIXED: Proper parsing for created/updated at
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  // Helper method to parse dates with timezone handling
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now().toLocal();
    
    try {
      String dateString = value.toString().trim();
      
      // Debug log
      if (kDebugMode) {
        print('Parsing date: $dateString');
      }
      
      // If it doesn't have timezone, check format
      if (!dateString.endsWith('Z') && 
          !dateString.contains('+') && 
          !dateString.contains('-') &&
          !dateString.contains(' ')) {
        // It might be in format like "2024-01-01T12:00:00" without timezone
        // Add UTC timezone
        dateString = '${dateString}Z';
      }
      
      // Parse the date
      DateTime parsedDate = DateTime.parse(dateString);
      
      // Convert to local time
      return parsedDate.toLocal();
      
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing date $value: $e');
      }
      return DateTime.now().toLocal();
    }
  }

  // Helper method to parse JSON fields
  static Map<String, dynamic>? _parseJsonField(dynamic field) {
    if (field == null) return null;
    
    // If it's already a Map
    if (field is Map) {
      return Map<String, dynamic>.from(field);
    }
    
    // If it's a String, try to parse it as JSON
    if (field is String) {
      try {
        final parsed = json.decode(field);
        if (parsed is Map) {
          return Map<String, dynamic>.from(parsed);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to parse JSON field: $e');
        }
      }
    }
    
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'message_id': messageId,
      'content': content,
      'message_type': messageType,
      'direction': direction,
      'status': status,
      'timestamp': timestamp.toUtc().toIso8601String(), // Store as UTC
      'status_timestamp': statusTimestamp?.toUtc().toIso8601String(),
      'template_id': templateId,
      'media_info': mediaInfo,
      'raw_data': rawData,
      'created_at': createdAt.toUtc().toIso8601String(), // Store as UTC
      'updated_at': updatedAt.toUtc().toIso8601String(), // Store as UTC
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? messageId,
    String? content,
    String? messageType,
    String? direction,
    String? status,
    DateTime? timestamp,
    DateTime? statusTimestamp,
    String? templateId,
    Map<String, dynamic>? mediaInfo,
    Map<String, dynamic>? rawData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      messageId: messageId ?? this.messageId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      statusTimestamp: statusTimestamp ?? this.statusTimestamp,
      templateId: templateId ?? this.templateId,
      mediaInfo: mediaInfo ?? this.mediaInfo,
      rawData: rawData ?? this.rawData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, conversationId: $conversationId, content: ${content.length > 30 ? '${content.substring(0, 30)}...' : content}, direction: $direction, status: $status, time: $formattedTime)';
  }

  // Helper methods
  bool get isIncoming => direction == 'incoming';
  bool get isOutgoing => direction == 'outgoing';
  bool get isAiOutgoing => direction == 'ai_outgoing';
  bool get isSent => status == 'sent';
  bool get isDelivered => status == 'delivered';
  bool get isRead => status == 'read';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';

  // Check if message has media
  bool get hasMedia => mediaInfo != null && mediaInfo!.isNotEmpty;
  
  // Check if message is a specific type
  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isVideo => messageType == 'video';
  bool get isAudio => messageType == 'audio';
  bool get isDocument => messageType == 'document';
  bool get isLocation => messageType == 'location';
  bool get isContact => messageType == 'contacts';
  bool get isSticker => messageType == 'sticker';
  bool get isReaction => messageType == 'reaction';

  // Get media URL if available
  String? get mediaUrl {
    if (mediaInfo == null) return null;
    return mediaInfo!['url']?.toString() ?? 
           mediaInfo!['link']?.toString() ?? 
           mediaInfo!['media_url']?.toString();
  }

  // Get file name for documents
  String? get fileName {
    if (mediaInfo == null) return null;
    return mediaInfo!['filename']?.toString() ?? 
           mediaInfo!['name']?.toString();
  }

  // Get file size for documents/media
  String? get fileSize {
    if (mediaInfo == null) return null;
    return mediaInfo!['filesize']?.toString() ?? 
           mediaInfo!['size']?.toString();
  }

  // Get mime type
  String? get mimeType {
    if (mediaInfo == null) return null;
    return mediaInfo!['mime_type']?.toString() ?? 
           mediaInfo!['type']?.toString();
  }

  // ========== TIME FORMATTING METHODS ==========
  
  // Get formatted time (e.g., "14:30")
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
  
  // Get formatted time with AM/PM (e.g., "2:30 PM")
  String get formattedTime12Hour {
    final hour = timestamp.hour % 12;
    final hourDisplay = hour == 0 ? 12 : hour;
    final amPm = timestamp.hour < 12 ? 'AM' : 'PM';
    return '$hourDisplay:${timestamp.minute.toString().padLeft(2, '0')} $amPm';
  }
  
  // Get formatted date (e.g., "Today", "Yesterday", "Mon", "01/01")
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[timestamp.weekday - 1];
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}';
    }
  }
  
  // Get full formatted date (e.g., "Mon, 01 Jan 2024")
  String get formattedFullDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[timestamp.weekday - 1]}, ${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}';
  }
  
  // Check if message is from today
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year && 
           timestamp.month == now.month && 
           timestamp.day == now.day;
  }
  
  // Check if message is from yesterday
  bool get isYesterday {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return timestamp.year == yesterday.year && 
           timestamp.month == yesterday.month && 
           timestamp.day == yesterday.day;
  }
  
  // Check if message is recent (within last hour)
  bool get isRecent {
    final now = DateTime.now();
    return now.difference(timestamp).inMinutes < 60;
  }
}

// Extension for list operations
extension MessageListExtensions on List<Message> {
  List<Message> get incomingMessages => where((m) => m.isIncoming).toList();
  List<Message> get outgoingMessages => where((m) => m.isOutgoing).toList();
  List<Message> get aiMessages => where((m) => m.isAiOutgoing).toList();
  List<Message> get unreadMessages => where((m) => m.isIncoming && m.status == 'delivered').toList();
  
  List<Message> sortByTimestamp({bool ascending = true}) {
    return List<Message>.from(this)
      ..sort((a, b) => ascending
          ? a.timestamp.compareTo(b.timestamp)
          : b.timestamp.compareTo(a.timestamp));
  }
  
  List<Message> getMessagesByDate(DateTime date) {
    return where((m) => 
      m.timestamp.year == date.year &&
      m.timestamp.month == date.month &&
      m.timestamp.day == date.day
    ).toList();
  }
  
  Map<DateTime, List<Message>> groupByDate() {
    final Map<DateTime, List<Message>> grouped = {};
    
    for (final message in this) {
      final date = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day
      );
      
      grouped.putIfAbsent(date, () => []).add(message);
    }
    
    return grouped;
  }
}