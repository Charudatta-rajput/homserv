import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import 'provider_list_viewmodel.dart';
import 'provider_list_state.dart';
import '../../../data/models/provider.dart';

class ProviderListScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final int fixedPrice;

  const ProviderListScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.fixedPrice,
  });

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  late ProviderListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProviderListViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadProviders(
        serviceId: widget.serviceId,
        serviceName: widget.serviceName,
        radius: 10,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return provider_package.ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.serviceName),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _viewModel.loadProviders(
                  serviceId: widget.serviceId,
                  serviceName: widget.serviceName,
                  radius: 10,
                );
              },
            ),
          ],
        ),
        body: provider_package.Consumer<ProviderListViewModel>(
          builder: (context, viewModel, child) {
            final state = viewModel.state;

            if (state is ProviderListError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
                viewModel.resetError();
              });
              return _buildErrorState(context);
            }

            if (state is ProviderListLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is ProviderListLoaded) {
              if (state.providers.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildProviderList(context, state);
            }

            return const Center(
              child: Text('Loading providers...'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProviderList(BuildContext context, ProviderListLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.providers.length,
      itemBuilder: (context, index) {
        final provider = state.providers[index];
        return _buildProviderCard(context, provider);
      },
    );
  }

  Widget _buildProviderCard(BuildContext context, Provider provider) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: Name + Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    provider.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      provider.getRatingDisplay(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${provider.totalJobsCompleted} jobs)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row: Experience + Distance
            Row(
              children: [
                const Icon(Icons.work_history, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${provider.experienceYears} years experience',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  provider.getDistanceDisplay(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row: Price + Book Now
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${widget.fixedPrice}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking coming soon!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Book Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'This service is not available in your area yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try another service or check back later',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _viewModel.loadProviders(
                  serviceId: widget.serviceId,
                  serviceName: widget.serviceName,
                  radius: 10,
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _viewModel.loadProviders(
                  serviceId: widget.serviceId,
                  serviceName: widget.serviceName,
                  radius: 10,
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}