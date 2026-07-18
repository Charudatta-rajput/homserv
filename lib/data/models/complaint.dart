import 'package:flutter/material.dart';

class Complaint {
  final String id;
  final String? bookingId;
  final String raisedBy;
  final String reason;
  final List<String>? evidencePhotos;
  final String status;
  final String? resolvedByAdminId;
  final int? refundAmount;
  final DateTime createdAt;
  final String? bookingNumber;
  final String? serviceName;
  final String? providerName;

  Complaint({
    required this.id,
    this.bookingId,
    required this.raisedBy,
    required this.reason,
    this.evidencePhotos,
    required this.status,
    this.resolvedByAdminId,
    this.refundAmount,
    required this.createdAt,
    this.bookingNumber,
    this.serviceName,
    this.providerName,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map<String, dynamic>?;
    return Complaint(
      id: json['id'] ?? '',
      bookingId: json['booking_id'],
      raisedBy: json['raised_by'] ?? '',
      reason: json['reason'] ?? '',
      evidencePhotos: json['evidence_photos'] != null
          ? List<String>.from(json['evidence_photos'])
          : null,
      status: json['status'] ?? 'open',
      resolvedByAdminId: json['resolved_by_admin_id'],
      refundAmount: json['refund_amount'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      bookingNumber: booking?['booking_number'],
      serviceName: booking?['service']?['name'],
      providerName: booking?['provider']?['name'],
    );
  }

  String getStatusDisplay() {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon() {
    switch (status) {
      case 'open':
        return Icons.pending;
      case 'in_progress':
        return Icons.hourglass_empty;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}