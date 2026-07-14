import 'package:flutter/material.dart';

class Booking {
  final String id;
  final String bookingNumber;
  final String customerId;
  final String? providerId;
  final String serviceId;
  final DateTime scheduledTime;
  final String status;
  final int totalPrice;
  final int? partsCost;
  final int totalAmount;
  final String? address;
  final String? notes;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? customerConfirmedAt;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final String? providerName;
  final String? serviceName;
  final int? servicePrice;

  Booking({
    required this.id,
    required this.bookingNumber,
    required this.customerId,
    this.providerId,
    required this.serviceId,
    required this.scheduledTime,
    required this.status,
    required this.totalPrice,
    this.partsCost,
    required this.totalAmount,
    this.address,
    this.notes,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.customerConfirmedAt,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.providerName,
    this.serviceName,
    this.servicePrice,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      bookingNumber: json['booking_number'] ?? '',
      customerId: json['customer_id'] ?? '',
      providerId: json['provider_id'],
      serviceId: json['service_id'] ?? '',
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      totalPrice: json['total_price'] ?? 0,
      partsCost: json['parts_cost'],
      totalAmount: json['total_amount'] ?? 0,
      address: json['address'],
      notes: json['notes'],
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      customerConfirmedAt: json['customer_confirmed_at'] != null
          ? DateTime.parse(json['customer_confirmed_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      customerName: json['customer']?['name'] ?? json['customer_name'],
      customerPhone: json['customer']?['phone'] ?? json['customer_phone'],
      providerName: json['provider']?['name'] ?? json['provider_name'],
      serviceName: json['service']?['name'] ?? json['service_name'],
      servicePrice: json['service']?['fixed_price'] ?? json['service_price'],
    );
  }

  String getStatusDisplay() {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'disputed':
        return 'Disputed';
      default:
        return status;
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red;
      case 'disputed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon() {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.engineering;
      case 'completed':
        return Icons.check_circle;
      case 'confirmed':
        return Icons.verified;
      case 'cancelled':
        return Icons.cancel;
      case 'rejected':
        return Icons.close;
      case 'disputed':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }
}