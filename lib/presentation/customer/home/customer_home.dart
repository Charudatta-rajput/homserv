import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bookings/my_bookings_screen.dart';
import '../services/service_screen.dart';
import '../support/support_screen.dart';
import '../profile/profile_screen.dart';
import '../providers/provider_list_screen.dart';
import 'customer_home_viewmodel.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/service.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerHomeViewModel()..loadRecentBookings(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: const _CustomerHomeContent(),
      ),
    );
  }
}

class _CustomerHomeContent extends StatelessWidget {
  const _CustomerHomeContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerHomeViewModel>();
    final recentBookings = viewModel.recentBookings;
    final status = viewModel.status;

    return Column(
      children: [
        const _Header(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _QuickActions(),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Bookings',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyBookingsScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (status == CustomerHomeStateStatus.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                if (status == CustomerHomeStateStatus.error)
                  _buildErrorState(viewModel),
                if (status == CustomerHomeStateStatus.loaded && recentBookings.isEmpty)
                  _buildEmptyState(),
                if (status == CustomerHomeStateStatus.loaded && recentBookings.isNotEmpty)
                  _buildRecentBookingsList(recentBookings),
                const SizedBox(height: 24),
                const _Footer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBookingsList(List<Booking> bookings) {
    return Column(
      children: bookings.map((booking) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.construction,
                  size: 20,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName ?? 'Service',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '₹${booking.totalPrice}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: booking.getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking.getStatusDisplay(),
                            style: TextStyle(
                              fontSize: 10,
                              color: booking.getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0F766E).withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            size: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 6),
          Text(
            'No recent bookings',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Book a service to get started',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CustomerHomeViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            viewModel.errorMessage ?? 'Could not load bookings',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: viewModel.retry,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0F766E),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ========== HEADER WITH OVERLAY (perfected alignment) ==========
class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _searchBarKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  List<Service> _suggestions = [];

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(BuildContext context) {
    _removeOverlay();

    final RenderBox? renderBox = _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double width = renderBox.size.width;
    final double height = renderBox.size.height;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _focusNode.unfocus();
          _removeOverlay();
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy + height + 6,
              width: width,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _suggestions.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No services found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 0,
                      color: Colors.grey.shade100,
                    ),
                    itemBuilder: (context, index) {
                      final service = _suggestions[index];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Icon(
                          Icons.search,
                          size: 18,
                          color: const Color(0xFF0F766E),
                        ),
                        title: Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '₹${service.fixedPrice}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        onTap: () {
                          _focusNode.unfocus();
                          _searchController.clear();
                          _suggestions = [];
                          _removeOverlay();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderListScreen(
                                serviceId: service.id,
                                serviceName: service.name,
                                fixedPrice: service.fixedPrice,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerHomeViewModel>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Sahaya',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 22),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.white70, size: 22),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              key: _searchBarKey,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (value) {
                  viewModel.searchServices(value.trim());
                  setState(() {
                    _suggestions = viewModel.searchResults;
                  });
                  if (value.isNotEmpty && _suggestions.isNotEmpty && _focusNode.hasFocus) {
                    _showOverlay(context);
                  } else {
                    _removeOverlay();
                  }
                },
                onSubmitted: (value) {
                  if (_suggestions.isNotEmpty) {
                    final service = _suggestions.first;
                    _focusNode.unfocus();
                    _searchController.clear();
                    _suggestions = [];
                    _removeOverlay();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderListScreen(
                          serviceId: service.id,
                          serviceName: service.name,
                          fixedPrice: service.fixedPrice,
                        ),
                      ),
                    );
                  } else {
                    _focusNode.unfocus();
                    _removeOverlay();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search for services...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade500, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _suggestions = [];
                      });
                      viewModel.searchServices('');
                      _removeOverlay();
                      _focusNode.requestFocus();
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== QUICK ACTIONS ==========
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                letterSpacing: 0.2,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServicesScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickActionCard(
              icon: Icons.build,
              label: 'Book Service',
              color: const Color(0xFF0F766E),
              iconBgColor: const Color(0xFFCCFBF1),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServicesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _QuickActionCard(
              icon: Icons.calendar_today,
              label: 'My Bookings',
              color: const Color(0xFF1E293B),
              iconBgColor: const Color(0xFFF1F5F9),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyBookingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickActionCard(
              icon: Icons.location_on,
              label: 'Track Booking',
              color: const Color(0xFFB45309),
              iconBgColor: const Color(0xFFFEF3C7),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '📍 Track your provider\'s location in real-time when they are on the way!',
                    ),
                    backgroundColor: Color(0xFF0F766E),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _QuickActionCard(
              icon: Icons.headset_mic,
              label: 'Support',
              color: const Color(0xFF6D28D9),
              iconBgColor: const Color(0xFFEDE9FE),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupportScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Divider(
            color: Colors.grey.shade200,
            thickness: 0.3,
          ),
          const SizedBox(height: 10),
          Text(
            'Sahaya',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Support when you need it',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}