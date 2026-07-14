import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../history/completed_history_screen.dart';
import 'provider_dashboard_viewmodel.dart';
import 'provider_dashboard_state.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  late ProviderDashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProviderDashboardViewModel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        _viewModel.setProviderId(userId);
        _viewModel.loadDashboard();
      }
    });
  }

  // ============ Phone Call ============
  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: cleanedNumber,
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      _showManualDialDialog(cleanedNumber);
    }
  }

  void _showManualDialDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Call Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unable to open dialer automatically.'),
            const SizedBox(height: 12),
            const Text(
              'Please call manually:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      phoneNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _makePhoneCallDirect(phoneNumber);
            },
            icon: const Icon(Icons.call, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _makePhoneCallDirect(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ============ Open Google Maps ============
  Future<void> _openAddressInMaps(String address) async {
    if (address.isEmpty) return;
    final encodedAddress = Uri.encodeComponent(address);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'Provider Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black54),
              onPressed: () {
                _viewModel.loadDashboard();
              },
            ),
            IconButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/provider-login');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.black54),
            ),
          ],
        ),
        body: Consumer<ProviderDashboardViewModel>(
          builder: (context, viewModel, child) {
            final state = viewModel.state;

            if (state is ProviderDashboardError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
                viewModel.resetError();
              });
              return _buildErrorState();
            }

            if (state is ProviderDashboardLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                ),
              );
            }

            if (state is ProviderDashboardLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(state),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),

// Stats Grid
                    Row(
                      children: [
                        _buildStatsCard(
                          icon: Icons.pending_actions,
                          label: 'Pending',
                          value: state.totalPending.toString(),
                          color: Colors.orange,
                          bgColor: Colors.orange.shade50,
                        ),
                        const SizedBox(width: 12),
                        _buildStatsCard(
                          icon: Icons.check_circle_outline,
                          label: 'Accepted',
                          value: state.totalAccepted.toString(),
                          color: Colors.blue,
                          bgColor: Colors.blue.shade50,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // ✅ CORRECT: Expanded directly inside Row, GestureDetector inside it
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CompletedHistoryScreen(),
                                ),
                              );
                            },
                            child: _buildStatsCard(
                              icon: Icons.done_all,
                              label: 'Completed',
                              value: state.totalCompleted.toString(),
                              color: Colors.green,
                              bgColor: Colors.green.shade50,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatsCard(
                            icon: Icons.currency_rupee,
                            label: 'Earnings',
                            value: '₹${state.totalEarnings}',
                            color: Colors.purple,
                            bgColor: Colors.purple.shade50,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Pending Requests',
                      count: state.totalPending,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    if (state.pendingBookings.isEmpty)
                      _buildEmptyState(
                        icon: Icons.inbox,
                        message: 'No pending requests',
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.pendingBookings.length,
                        itemBuilder: (context, index) {
                          final booking = state.pendingBookings[index];
                          return _buildPendingBookingCard(
                            context,
                            booking,
                            viewModel,
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Active Jobs',
                      count: state.totalAccepted,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    if (state.acceptedBookings.isEmpty)
                      _buildEmptyState(
                        icon: Icons.work_off,
                        message: 'No active jobs',
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.acceptedBookings.length,
                        itemBuilder: (context, index) {
                          final booking = state.acceptedBookings[index];
                          return _buildAcceptedBookingCard(
                            context,
                            booking,
                            viewModel,
                          );
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            }

            return const Center(
              child: Text('Loading dashboard...'),
            );
          },
        ),
      ),
    );
  }

  // ============ UI Components ============

  Widget _buildWelcomeCard(ProviderDashboardLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👋 Hello,',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'Provider',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                const Text('Verified', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('You have', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.totalPending}',
                        style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('pending requests', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  // ============ Booking Cards ============

  Widget _buildPendingBookingCard(
      BuildContext context,
      dynamic booking,
      ProviderDashboardViewModel viewModel,
      ) {
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
            _buildBookingHeader(booking),
            const SizedBox(height: 8),
            _buildBookingDetails(booking),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      viewModel.acceptBooking(booking.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showRejectConfirmation(context, booking.id, viewModel);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedBookingCard(
      BuildContext context,
      dynamic booking,
      ProviderDashboardViewModel viewModel,
      ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.blue.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingHeader(booking, isAccepted: true),
            const SizedBox(height: 8),
            _buildBookingDetails(booking),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showCompleteConfirmation(context, booking.id, viewModel);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Mark as Complete', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                _buildCallButton(booking.customerPhone),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingHeader(dynamic booking, {bool isAccepted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            booking.serviceName ?? 'Service',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isAccepted ? Colors.blue.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '₹${booking.totalPrice}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isAccepted ? Colors.blue.shade700 : Colors.green.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetails(dynamic booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              booking.customerName ?? 'Customer',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (booking.customerPhone != null)
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                booking.customerPhone!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${booking.scheduledTime.day}/${booking.scheduledTime.month}/${booking.scheduledTime.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${booking.scheduledTime.hour.toString().padLeft(2, '0')}:${booking.scheduledTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        if (booking.address != null && booking.address!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  booking.address!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.location_on, size: 18, color: Color(0xFF2563EB)),
                onPressed: () => _openAddressInMaps(booking.address!),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
                tooltip: 'Open in Maps',
              ),
            ],
          ),
        ],
        if (booking.notes != null && booking.notes!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCallButton(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 50,
      height: 40,
      child: ElevatedButton(
        onPressed: () => _makePhoneCall(phoneNumber),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          minimumSize: const Size(44, 38),
        ),
        child: const Icon(Icons.call, size: 20),
      ),
    );
  }

  // ============ Dialogs ============

  void _showRejectConfirmation(
      BuildContext context,
      String bookingId,
      ProviderDashboardViewModel viewModel,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Reject Booking?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to reject this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.rejectBooking(bookingId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Reject'),
          ),
        ],
      ),
    );
  }

  void _showCompleteConfirmation(
      BuildContext context,
      String bookingId,
      ProviderDashboardViewModel viewModel,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Complete Job?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Have you completed this job?'),
            SizedBox(height: 8),
            Text(
              'The customer will be notified to confirm.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not Yet')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.completeBooking(bookingId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );
  }

  // ============ Error State ============

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text('Please try again later', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _viewModel.loadDashboard(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}