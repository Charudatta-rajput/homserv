import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'provider_login_viewmodel.dart';
import 'provider_login_state.dart';
import '../signup/provider_signup_screen.dart';
import '../../provider/dashboard/provider_dashboard.dart';

class ProviderLogin extends StatefulWidget {
  const ProviderLogin({super.key});

  @override
  State<ProviderLogin> createState() => _ProviderLoginState();
}

class _ProviderLoginState extends State<ProviderLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProviderLoginViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Provider Login'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Consumer<ProviderLoginViewModel>(
              builder: (context, viewModel, child) {
                final state = viewModel.state;

                // Handle errors
                if (state is ProviderLoginError) {
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

                // Handle success
                if (state is ProviderLoginSuccess) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Check verification status
                    if (state.verificationStatus == 'pending') {
                      // Show pending verification dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Verification Pending'),
                          content: const Text(
                            'Your account is waiting for admin approval. '
                                'You will be notified once verified.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                await Supabase.instance.client.auth.signOut();
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext); // Close dialog
                                  Navigator.pop(context); // Go back
                                }
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      viewModel.resetState();
                    } else if (state.verificationStatus == 'approved') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ProviderDashboard()),
                      );
                      viewModel.resetState();
                    } else if (state.verificationStatus == 'rejected') {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Verification Rejected'),
                          content: const Text(
                            'Your application has been rejected. '
                                'Please contact support for more information.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                await Supabase.instance.client.auth.signOut();
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext); // Close dialog
                                  Navigator.pop(context); // Go back
                                }
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      viewModel.resetState();
                    } else {
                      // Default - go to dashboard
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ProviderDashboard()),
                      );
                      viewModel.resetState();
                    }
                  });
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.work, size: 64, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text(
                      'Provider Login',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Login to manage your services',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 48),

                    // Email
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: state is ProviderLoginLoading
                            ? null
                            : () {
                          viewModel.login(
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state is ProviderLoginLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('LOGIN', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProviderSignupScreen()),
                            );
                          },
                          child: const Text('Register as Provider'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}