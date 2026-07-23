import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider_list_screen.dart';
import 'service_viewmodel.dart';
import 'service_state.dart';
import '../../../data/models/service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late ServiceViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ServiceViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadServices();
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
            'Services',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          // Refresh button removed – now use pull‑to‑refresh
        ),
        body: Consumer<ServiceViewModel>(
          builder: (context, viewModel, child) {
            final state = viewModel.state;

            if (state is ServiceError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
                viewModel.resetError();
              });
              return const Center(
                child: Text('Failed to load services. Pull to refresh.'),
              );
            }

            if (state is ServiceLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                ),
              );
            }

            if (state is ServiceLoaded) {
              return RefreshIndicator(
                onRefresh: () => viewModel.refreshServices(),
                color: const Color(0xFF2563EB),
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  slivers: [
                    // Category Tabs (sticky header)
                    SliverPersistentHeader(
                      delegate: _CategoryHeaderDelegate(
                        categories: state.categories,
                        selectedCategory: state.selectedCategory,
                        onCategoryTap: viewModel.filterByCategory,
                      ),
                      pinned: true,
                    ),
                    // Services Grid
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final service = state.filteredServices[index];
                            return _buildServiceCard(context, service);
                          },
                          childCount: state.filteredServices.length,
                        ),
                      ),
                    ),
                    // Empty state (when no services)
                    if (state.filteredServices.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No services available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try selecting a different category',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            return const Center(
              child: Text('Tap refresh to load services'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Service service) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Service Icon with Gradient Background
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2563EB).withOpacity(0.12),
                      const Color(0xFF2563EB).withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getIconForService(service.name),
                  size: 36,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 12),
              // Service Name
              Text(
                service.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Price
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    '${service.fixedPrice}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Estimated Time
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${service.estimatedMinutes} min',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForService(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('plumber') || lowerName.contains('tap') || lowerName.contains('pipe')) {
      return Icons.plumbing;
    } else if (lowerName.contains('electrician') || lowerName.contains('switch') || lowerName.contains('wire')) {
      return Icons.electrical_services;
    } else if (lowerName.contains('ac') || lowerName.contains('air')) {
      return Icons.ac_unit;
    } else if (lowerName.contains('water') || lowerName.contains('tank')) {
      return Icons.water_damage;
    } else if (lowerName.contains('sofa') || lowerName.contains('carpet')) {
      return Icons.weekend;
    } else if (lowerName.contains('pest')) {
      return Icons.bug_report;
    } else if (lowerName.contains('painting') || lowerName.contains('painter')) {
      return Icons.brush;
    } else if (lowerName.contains('carpenter') || lowerName.contains('furniture')) {
      return Icons.handyman;
    } else if (lowerName.contains('moving') || lowerName.contains('helper')) {
      return Icons.moving;
    } else if (lowerName.contains('cctv')) {
      return Icons.videocam;
    } else if (lowerName.contains('fridge') || lowerName.contains('appliance')) {
      return Icons.kitchen;
    } else if (lowerName.contains('tv') || lowerName.contains('laptop')) {
      return Icons.devices;
    }

    return Icons.build;
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategoryTap;

  _CategoryHeaderDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  @override
  double get minExtent => 58;
  @override
  double get maxExtent => 58;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => onCategoryTap(category),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}