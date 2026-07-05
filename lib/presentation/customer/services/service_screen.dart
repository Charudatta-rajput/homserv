import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        appBar: AppBar(
          title: const Text('Services'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _viewModel.refreshServices();
              },
            ),
          ],
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
                child: CircularProgressIndicator(),
              );
            }

            if (state is ServiceLoaded) {
              return Column(
                children: [
                  // Category Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.categories.length,
                        itemBuilder: (context, index) {
                          final category = state.categories[index];
                          final isSelected = category == state.selectedCategory;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  viewModel.filterByCategory(category);
                                }
                              },
                              selectedColor: Colors.blue.shade100,
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.blue.shade900 : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Services Grid
                  Expanded(
                    child: state.filteredServices.isEmpty
                        ? const Center(
                      child: Text('No services available in this category'),
                    )
                        : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: state.filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = state.filteredServices[index];
                        return _buildServiceCard(context, service);
                      },
                    ),
                  ),
                ],
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
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to provider list screen
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => ProvidersScreen(serviceId: service.id),
          //   ),
          // );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Service Icon
              Icon(
                _getIconForService(service.name),
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              // Service Name
              Text(
                service.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Price
              Text(
                '₹${service.fixedPrice}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 2),
              // Estimated Time
              Text(
                '${service.estimatedMinutes} min',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
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