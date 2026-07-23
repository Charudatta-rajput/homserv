import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String userId;
  final String? bookingId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? actionData;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.type,
    required this.title,
    required this.message,
    this.actionData,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      bookingId: json['booking_id'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      actionData: json['action_data'] is Map ? json['action_data'] : null,
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'booking_id': bookingId,
      'type': type,
      'title': title,
      'message': message,
      'action_data': actionData,
      'is_read': isRead,
    };
  }

  IconData get icon {
    switch (type) {
      case 'booking_accepted':
        return Icons.check_circle;
      case 'booking_completed':
        return Icons.star;
      case 'booking_cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'booking_accepted':
        return Colors.green;
      case 'booking_completed':
        return Colors.orange;
      case 'booking_cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String get actionLabel {
    switch (type) {
      case 'booking_completed':
        return 'Rate';
      default:
        return 'View';
    }
  }
}