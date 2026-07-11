import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider_signup_viewmodel.dart';
import 'provider_signup_state.dart';
import '../location/location_picker_screen.dart';
import '../login/provider_login_screen.dart';
import '../../../data/models/service.dart';

class ProviderSignupScreen extends StatefulWidget {
  const ProviderSignupScreen({super.key});

  @override
  State<ProviderSignupScreen> createState() => _ProviderSignupScreenState();
}

class _ProviderSignupScreenState extends State<ProviderSignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  bool _obscurePassword = true;
  bool _showProfessionalFields = false;

  String _selectedAddress = '';
  double _selectedLat = 0;
  double _selectedLng = 0;
  bool _locationSelected = false;

  String _selectedTrade = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() {
      final viewModel = Provider.of<ProviderSignupViewModel>(context, listen: false);
      viewModel.loadServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProviderSignupViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_showProfessionalFields ? 'Professional Details' : 'Basic Information'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_showProfessionalFields) {
                setState(() => _showProfessionalFields = false);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Consumer<ProviderSignupViewModel>(
          builder: (context, viewModel, child) {
            final state = viewModel.state;

            if (viewModel.availableServices.isEmpty && !viewModel.servicesLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                viewModel.loadServices();
              });
            }

            if (state is ProviderSignupError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
                viewModel.resetError();
              });
            }

            if (state is ProviderSignupSuccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('Registration Submitted'),
                    content: Text(state.message),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const ProviderLogin()),
                          );
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                viewModel.resetState();
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_showProfessionalFields) ...[
                    const Icon(Icons.work_outline, size: 48, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text(
                      'Create Provider Account',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join as a service provider',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationPickerScreen(
                              name: _nameController.text.trim(),
                              phone: _phoneController.text.trim(),
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            ),
                          ),
                        );
                        if (result != null && mounted) {
                          setState(() {
                            _selectedAddress = result.address;
                            _selectedLat = result.latitude;
                            _selectedLng = result.longitude;
                            _locationSelected = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.location_on),
                      label: Text(_locationSelected ? 'Location Selected ✓' : 'Select Address on Map *'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _locationSelected ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    if (_locationSelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _selectedAddress,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_nameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter your full name')),
                            );
                            return;
                          }
                          if (_phoneController.text.length != 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter valid 10-digit phone number')),
                            );
                            return;
                          }
                          if (!_emailController.text.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter valid email address')),
                            );
                            return;
                          }
                          if (_passwordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password must be at least 6 characters')),
                            );
                            return;
                          }
                          if (!_locationSelected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Select your address on map')),
                            );
                            return;
                          }
                          setState(() => _showProfessionalFields = true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('NEXT', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.badge, size: 48, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text(
                      'Professional Details',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),

                    // Trade Dropdown - Simplified
                    _buildSimpleTradeDropdown(viewModel),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _experienceController,
                      decoration: const InputDecoration(
                        labelText: 'Experience (years) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timeline),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Documents for Verification',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    _buildDocumentTile(
                      context,
                      title: 'Aadhaar Card *',
                      hasFile: viewModel.aadharImage != null,
                      onTap: () => viewModel.pickImage('aadhar'),
                      fileName: viewModel.aadharImage?.name,
                    ),
                    const SizedBox(height: 12),

                    _buildDocumentTile(
                      context,
                      title: 'ITI / Trade Certificate *',
                      hasFile: viewModel.itiImage != null,
                      onTap: () => viewModel.pickImage('iti'),
                      fileName: viewModel.itiImage?.name,
                    ),
                    const SizedBox(height: 12),

                    _buildDocumentTile(
                      context,
                      title: 'Police Verification (Optional)',
                      hasFile: viewModel.policeImage != null,
                      onTap: () => viewModel.pickImage('police'),
                      fileName: viewModel.policeImage?.name,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: state is ProviderSignupLoading
                            ? null
                            : () {
                          if (_selectedTrade.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select your service')),
                            );
                            return;
                          }
                          if (_experienceController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter experience years')),
                            );
                            return;
                          }
                          if (viewModel.aadharImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Upload Aadhaar Card')),
                            );
                            return;
                          }
                          if (viewModel.itiImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Upload ITI / Trade Certificate')),
                            );
                            return;
                          }

                          viewModel.registerProvider(
                            name: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                            address: _selectedAddress,
                            latitude: _selectedLat,
                            longitude: _selectedLng,
                            trade: _selectedTrade,
                            experience: int.parse(_experienceController.text.trim()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state is ProviderSignupLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('REGISTER', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // SIMPLIFIED TRADE DROPDOWN - No complex layouts
  Widget _buildSimpleTradeDropdown(ProviderSignupViewModel viewModel) {
    if (viewModel.servicesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (viewModel.availableServices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.shade50,
        ),
        child: const Text(
          'No services available. Please contact admin.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedTrade.isEmpty ? null : _selectedTrade,
      decoration: const InputDecoration(
        labelText: 'Select Your Service *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.work),
      ),
      items: viewModel.availableServices.map((Service service) {
        return DropdownMenuItem<String>(
          value: service.name,
          child: Text(
            '${service.name}  (₹${service.fixedPrice})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedTrade = newValue!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your service';
        }
        return null;
      },
    );
  }

  Widget _buildDocumentTile(BuildContext context, {
    required String title,
    required bool hasFile,
    required VoidCallback onTap,
    String? fileName,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(hasFile ? Icons.check_circle : Icons.upload_file,
            color: hasFile ? Colors.green : Colors.grey),
        title: Text(title),
        subtitle: fileName != null ? Text(fileName, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}