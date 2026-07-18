import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../data/models/user.dart';
import '../../auth/location/location_picker_screen.dart';
import 'profile_viewmodel.dart';
import 'profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileViewModel _viewModel;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        _viewModel.setUserId(userId);
        _viewModel.loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            if (_isEditing)
              TextButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0F766E),
                  ),
                )
                    : const Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        body: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            final state = viewModel.state;

            if (state is ProfileError) {
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

            if (state is ProfileLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0F766E),
                ),
              );
            }

            if (state is ProfileLoaded) {
              if (!_isEditing) {
                _loadUserData(state.user);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Avatar
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0F766E).withOpacity(0.15),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Edit Toggle
                    if (!_isEditing)
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Profile'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Name
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    // Phone (read-only)
                    _buildTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // Email (read-only)
                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // Address (editable)
                    _buildTextField(
                      label: 'Address',
                      controller: _addressController,
                      enabled: _isEditing,
                      maxLines: 3,
                    ),

                    if (_isEditing) ...[
                      const SizedBox(height: 12),
                      // Update Location Button
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationPickerScreen(
                                name: _nameController.text.trim(),
                                phone: _phoneController.text.trim(),
                                email: _emailController.text.trim(),
                                password: '',
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _addressController.text = result.address;
                            });
                          }
                        },
                        icon: const Icon(Icons.location_on, size: 18),
                        label: const Text('Update Address on Map'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          _showLogoutConfirmation(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'LOGOUT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }

            // Initial state - show loading
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0F766E),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _loadUserData(User user) {
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    _emailController.text = user.email;
    _addressController.text = user.address ?? '';
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _viewModel.updateProfile(
        name: name,
        address: address.isNotEmpty ? address : null,
      );


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      // Error is handled by ViewModel error state
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/customer-login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}