import 'package:flutter/material.dart';
import 'package:homserv/presentation/customer/support/support_state.dart';
import 'package:homserv/presentation/customer/support/support_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/complaint.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  late ComplaintViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ComplaintViewModel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        _viewModel.setUserId(userId);
        _viewModel.loadComplaints();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'My Complaints',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black54),
              onPressed: () {
                _viewModel.loadComplaints();
              },
            ),
          ],
        ),
        body: Consumer<ComplaintViewModel>(
          builder: (context, viewModel, child) {
            final state = viewModel.state;

            if (state is ComplaintError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
                viewModel.resetError();
              });
              return const Center(
                child: Text('Failed to load complaints'),
              );
            }

            if (state is ComplaintLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0F766E),
                ),
              );
            }

            if (state is ComplaintLoaded) {
              if (state.complaints.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.complaints.length,
                itemBuilder: (context, index) {
                  final complaint = state.complaints[index];
                  return _buildComplaintCard(complaint);
                },
              );
            }

            return const Center(
              child: Text('No complaints found'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: Booking # + Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    complaint.bookingNumber != null
                        ? 'Booking #${complaint.bookingNumber}'
                        : 'General Issue',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: complaint.getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: complaint.getStatusColor(),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        complaint.getStatusIcon(),
                        size: 12,
                        color: complaint.getStatusColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        complaint.getStatusDisplay(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: complaint.getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Service name
            if (complaint.serviceName != null)
              Text(
                'Service: ${complaint.serviceName}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            const SizedBox(height: 6),

            // Reason
            Text(
              complaint.reason,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Date
            Text(
              '${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),

            // Evidence photos indicator
            if (complaint.evidencePhotos != null &&
                complaint.evidencePhotos!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.image,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${complaint.evidencePhotos!.length} photo(s) attached',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

            // ===== NEW: Resolution details (only when resolved) =====
            if (complaint.status == 'resolved') ...[
              if (complaint.resolutionNotes != null &&
                  complaint.resolutionNotes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Resolution: ${complaint.resolutionNotes}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              if (complaint.refundAmount != null && complaint.refundAmount! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.currency_rupee,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Refund: ₹${complaint.refundAmount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inbox,
                size: 64,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No complaints yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your complaints will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}