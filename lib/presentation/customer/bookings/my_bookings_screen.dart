import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'my_bookings_viewmodel.dart';
import 'my_bookings_state.dart';
import '../../../data/models/booking.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final viewModel = context.read<MyBookingsViewModel>();
        viewModel.setCustomerId(userId);
        viewModel.loadBookings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyBookingsViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<MyBookingsViewModel>().loadBookings();
              },
            ),
          ],
        ),
        body: Consumer<MyBookingsViewModel>(
          builder: (context, viewModel, child) {
            final state = viewModel.state;

            if (state is MyBookingsError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
                viewModel.resetError();
              });
              return const Center(
                child: Text('Failed to load bookings. Pull to refresh.'),
              );
            }

            if (state is MyBookingsLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is MyBookingsLoaded) {
              if (state.bookings.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No bookings yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Book a service to get started',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 45,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildFilterChip('All', state.selectedFilter, viewModel),
                          _buildFilterChip('pending', state.selectedFilter, viewModel),
                          _buildFilterChip('accepted', state.selectedFilter, viewModel),
                          _buildFilterChip('in_progress', state.selectedFilter, viewModel),
                          _buildFilterChip('completed', state.selectedFilter, viewModel),
                          _buildFilterChip('confirmed', state.selectedFilter, viewModel),
                          _buildFilterChip('cancelled', state.selectedFilter, viewModel),
                        ],
                      ),
                    ),
                  ),

                  // Bookings List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = state.filteredBookings[index];
                        return _buildBookingCard(context, booking, viewModel);
                      },
                    ),
                  ),
                ],
              );
            }

            return const Center(
              child: Text('No bookings found'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String selectedFilter, MyBookingsViewModel viewModel) {
    final isSelected = label == selectedFilter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label.toUpperCase()),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            viewModel.filterByStatus(label);
          }
        },
        selectedColor: Colors.blue.shade100,
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue.shade900 : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, MyBookingsViewModel viewModel) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Booking Number & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.bookingNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: booking.getStatusColor(),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        booking.getStatusIcon(),
                        size: 14,
                        color: booking.getStatusColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.getStatusDisplay(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: booking.getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Service Name
            Text(
              booking.serviceName ?? 'Service',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),

            // Provider Name
            if (booking.providerName != null)
              Text(
                'Provider: ${booking.providerName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            const SizedBox(height: 8),

            // Details Row
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${booking.scheduledTime.day}/${booking.scheduledTime.month}/${booking.scheduledTime.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${booking.scheduledTime.hour.toString().padLeft(2, '0')}:${booking.scheduledTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.currency_rupee, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${booking.totalPrice}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActionButtons(context, booking, viewModel),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, Booking booking, MyBookingsViewModel viewModel) {
    final List<Widget> buttons = [];

    if (booking.status == 'pending') {
      buttons.add(
        TextButton(
          onPressed: () {
            _showCancelConfirmation(context, booking.id, viewModel);
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (booking.status == 'completed') {
      buttons.add(
        TextButton(
          onPressed: () {
            viewModel.confirmBooking(booking.id);
          },
          child: const Text(
            'Confirm Completion',
            style: TextStyle(color: Colors.green),
          ),
        ),
      );
    }

    if (booking.status == 'confirmed') {
      buttons.add(
        TextButton(
          onPressed: () {
            _showRatingDialog(context, booking.id, viewModel);
          },
          child: const Text(
            'Rate',
            style: TextStyle(color: Colors.orange),
          ),
        ),
      );
    }

    // View Details button
    buttons.add(
      TextButton(
        onPressed: () {
          // Navigate to booking detail
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => BookingDetailScreen(bookingId: booking.id),
          //   ),
          // );
        },
        child: const Text('View Details'),
      ),
    );

    return buttons;
  }

  void _showCancelConfirmation(BuildContext context, String bookingId, MyBookingsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.cancelBooking(bookingId);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String bookingId, MyBookingsViewModel viewModel) {
    double rating = 3;
    String review = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Experience'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                        size: 36,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Review (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    review = value;
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.rateBooking(
                bookingId: bookingId,
                rating: rating.toInt(),
                review: review.isNotEmpty ? review : null,
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}