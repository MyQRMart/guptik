import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:guptik/config/app_config.dart';
import 'package:http/http.dart' as http;

class WhatsAppBusinessService {
  static final WhatsAppBusinessService _instance = WhatsAppBusinessService._internal();
  factory WhatsAppBusinessService() => _instance;
  WhatsAppBusinessService._internal();

  final String _baseUrl = AppConfig.whatsappApiBaseUrl;
  final String _accessToken = AppConfig.whatsappAccessToken;
  final String _phoneNumberId = AppConfig.whatsappPhoneNumberId;
  final String _businessAccountId = AppConfig.whatsappBusinessAccountId;

  // Get headers for API requests
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json',
  };

  // Get Business Profile Information
  Future<BusinessProfile?> getBusinessProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$_phoneNumberId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusinessProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching business profile: $e');
      return null;
    }
  }

  // Get Message Analytics
  Future<MessageAnalytics?> getMessageAnalytics() async {
    try {
      // Get analytics from WhatsApp Business API
      final response = await http.get(
        Uri.parse('$_baseUrl/$_businessAccountId/conversation_analytics'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MessageAnalytics.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching message analytics: $e');
      return null;
    }
  }

  // Get Phone Number Status
  Future<PhoneNumberStatus?> getPhoneNumberStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$_phoneNumberId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PhoneNumberStatus.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching phone number status: $e');
      return null;
    }
  }

  // Get Quality Rating
  Future<QualityRating?> getQualityRating() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$_phoneNumberId/quality_rating'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QualityRating.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching quality rating: $e');
      return null;
    }
  }

  // Get Live Dashboard Data (combines all data)
  Future<DashboardData?> getLiveDashboardData() async {
    try {
      final futures = await Future.wait([
        getBusinessProfile(),
        getMessageAnalytics(),
        getPhoneNumberStatus(),
        getQualityRating(),
      ]);

      return DashboardData(
        businessProfile: futures[0] as BusinessProfile?,
        messageAnalytics: futures[1] as MessageAnalytics?,
        phoneNumberStatus: futures[2] as PhoneNumberStatus?,
        qualityRating: futures[3] as QualityRating?,
      );
    } catch (e) {
      debugPrint('Error fetching live dashboard data: $e');
      return null;
    }
  }
}

// Data Models
class BusinessProfile {
  final String? displayName;
  final String? phoneNumber;
  final String? status;
  final String? verificationStatus;

  BusinessProfile({
    this.displayName,
    this.phoneNumber,
    this.status,
    this.verificationStatus,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      displayName: json['display_phone_number'] ?? json['verified_name'],
      phoneNumber: json['phone_number'],
      status: json['code_verification_status'],
      verificationStatus: json['status'],
    );
  }
}

class MessageAnalytics {
  final int marketing;
  final int authentication;
  final int service;
  final int utility;
  final int total;
  final int sent;
  final int delivered;
  final double marketingCost;
  final double authenticationCost;
  final double serviceCost;
  final double utilityCost;
  final double totalCost;

  MessageAnalytics({
    this.marketing = 0,
    this.authentication = 0,
    this.service = 0,
    this.utility = 0,
    this.total = 0,
    this.sent = 0,
    this.delivered = 0,
    this.marketingCost = 0.0,
    this.authenticationCost = 0.0,
    this.serviceCost = 0.0,
    this.utilityCost = 0.0,
    this.totalCost = 0.0,
  });

  factory MessageAnalytics.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? [];
    int marketing = 0, authentication = 0, service = 0, utility = 0;
    double marketingCost = 0.0, authenticationCost = 0.0, serviceCost = 0.0, utilityCost = 0.0;

    for (var item in data) {
      final category = item['category'] ?? '';
      final count = item['count'] ?? 0;
      final cost = (item['cost'] ?? 0.0).toDouble();

      switch (category.toLowerCase()) {
        case 'marketing':
          marketing = count;
          marketingCost = cost;
          break;
        case 'authentication':
          authentication = count;
          authenticationCost = cost;
          break;
        case 'service':
          service = count;
          serviceCost = cost;
          break;
        case 'utility':
          utility = count;
          utilityCost = cost;
          break;
      }
    }

    final total = marketing + authentication + service + utility;
    final totalCost = marketingCost + authenticationCost + serviceCost + utilityCost;

    return MessageAnalytics(
      marketing: marketing,
      authentication: authentication,
      service: service,
      utility: utility,
      total: total,
      sent: json['messages_sent'] ?? total,
      delivered: json['messages_delivered'] ?? total,
      marketingCost: marketingCost,
      authenticationCost: authenticationCost,
      serviceCost: serviceCost,
      utilityCost: utilityCost,
      totalCost: totalCost,
    );
  }
}

class PhoneNumberStatus {
  final String status;
  final String phoneNumber;
  final String displayPhoneNumber;

  PhoneNumberStatus({
    required this.status,
    required this.phoneNumber,
    required this.displayPhoneNumber,
  });

  factory PhoneNumberStatus.fromJson(Map<String, dynamic> json) {
    return PhoneNumberStatus(
      status: json['code_verification_status'] ?? 'UNKNOWN',
      phoneNumber: json['phone_number'] ?? '',
      displayPhoneNumber: json['display_phone_number'] ?? '',
    );
  }
}

class QualityRating {
  final String rating;
  final String status;

  QualityRating({
    required this.rating,
    required this.status,
  });

  factory QualityRating.fromJson(Map<String, dynamic> json) {
    return QualityRating(
      rating: json['quality_score'] ?? 'Unknown',
      status: json['status'] ?? 'Unknown',
    );
  }
}

class DashboardData {
  final BusinessProfile? businessProfile;
  final MessageAnalytics? messageAnalytics;
  final PhoneNumberStatus? phoneNumberStatus;
  final QualityRating? qualityRating;

  DashboardData({
    this.businessProfile,
    this.messageAnalytics,
    this.phoneNumberStatus,
    this.qualityRating,
  });
}