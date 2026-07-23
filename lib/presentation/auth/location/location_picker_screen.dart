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
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'Select Location',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            Consumer<LocationPickerViewModel>(
              builder: (context, viewModel, child) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.my_location,
                      color: Color(0xFF0F766E),
                      size: 22,
                    ),
                    onPressed: () {
                      viewModel.refreshLocation();
                    },
                    tooltip: 'Get my location',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<LocationPickerViewModel>(
          builder: (context, viewModel, child) {
            final state = viewModel.state;
            final predictions = viewModel.predictions;

            if (state is LocationPickerError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
                viewModel.resetError();
              });
            }

            return Column(
              children: [
                // Search Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Icon(
                          Icons.search,
                          color: Color(0xFF0F766E),
                          size: 22,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search city, area, or address',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            viewModel.searchAutocomplete(value);
                          },
                        ),
                      ),
                      if (predictions.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            viewModel.clearPredictions();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),

                // Autocomplete Suggestions
                if (predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: predictions.length > 5 ? 5 : predictions.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade100,
                        height: 0,
                      ),
                      itemBuilder: (context, index) {
                        final prediction = predictions[index];
                        return ListTile(
                          leading: Icon(
                            Icons.location_on,
                            size: 18,
                            color: const Color(0xFF0F766E),
                          ),
                          title: Text(
                            prediction['description'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          onTap: () {
                            viewModel.selectPlace(prediction);
                          },
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 4),

                // Google Map
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: viewModel.selectedLocation,
                          zoom: 15,
                        ),
                        onMapCreated: viewModel.onMapCreated,
                        onTap: viewModel.onMapTapped,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        zoomGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        tiltGesturesEnabled: true,
                        markers: {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: viewModel.selectedLocation,
                            draggable: true,
                            onDragEnd: (newPosition) {
                              viewModel.onMapTapped(newPosition);
                            },
                          ),
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Address Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                              color: const Color(0xFF0F766E).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF0F766E),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Selected Address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: state is LocationPickerLoaded
                                ? const Color(0xFF0F766E).withOpacity(0.15)
                                : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          state is LocationPickerLoaded && state.address.isNotEmpty
                              ? state.address
                              : 'Tap on map or search to select your location',
                          style: TextStyle(
                            fontSize: 13,
                            color: state is LocationPickerLoaded
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
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
                            backgroundColor: state is LocationPickerLoaded
                                ? const Color(0xFF0F766E)
                                : Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'CONFIRM LOCATION',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}