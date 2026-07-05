import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_picker_viewmodel.dart';
import 'location_picker_state.dart';
import '../signup/customer_signup_state.dart';

class LocationPickerScreen extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final String password;

  const LocationPickerScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationPickerViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Your Location'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            Consumer<LocationPickerViewModel>(
              builder: (context, viewModel, child) {
                return IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () {
                    viewModel.refreshLocation();
                  },
                  tooltip: 'Get my location',
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Consumer<LocationPickerViewModel>(
            builder: (context, viewModel, child) {
              final state = viewModel.state;
              final predictions = viewModel.predictions;

              if (state is LocationPickerError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  viewModel.resetError();
                });
              }

              return Column(
                children: [
                  // Search Bar with Autocomplete
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search city, area, or address',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                viewModel.clearPredictions();
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            viewModel.searchAutocomplete(value);
                          },
                        ),
                        if (predictions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: predictions.length > 5 ? 5 : predictions.length,
                              itemBuilder: (context, index) {
                                final prediction = predictions[index];
                                return ListTile(
                                  title: Text(
                                    prediction['description'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    viewModel.selectPlace(prediction);
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Google Map - Increased height
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.57, // 45% of screen
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: viewModel.selectedLocation,
                        zoom: 14,
                      ),
                      onMapCreated: viewModel.onMapCreated,
                      onTap: viewModel.onMapTapped,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: {
                        Marker(
                          markerId: const MarkerId('selected'),
                          position: viewModel.selectedLocation,
                        ),
                      },
                    ),
                  ),

                  // Address Section - Compact
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state is LocationPickerLoaded && state.address.isNotEmpty
                                ? state.address
                                : 'Tap on map or search to select your location',
                            style: TextStyle(
                              color: state is LocationPickerLoaded ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: state is LocationPickerLoaded
                                ? () {
                              final locationData = LocationData(
                                address: state.address,
                                latitude: state.latitude,
                                longitude: state.longitude,
                              );
                              Navigator.pop(context, locationData);
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'CONFIRM LOCATION',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}