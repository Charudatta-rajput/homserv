import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../customer/home/customer_home.dart';
import '../../provider/dashboard/provider_dashboard.dart';
import 'customer_login_viewmodel.dart';
import 'customer_login_state.dart';
import '../signup/customer_signup_screen.dart';
import 'provider_login_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
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
      create: (_) => CustomerLoginViewModel(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.home_repair_service, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Customer Login',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),

                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Consumer<CustomerLoginViewModel>(
                    builder: (context, viewModel, child) {
                      final state = viewModel.state;

                      if (state is CustomerLoginError) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                          );
                          viewModel.resetError();
                        });
                      }

                      if (state is CustomerLoginSuccess) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          // After login, check user role and navigate
                          final supabase = Supabase.instance.client;
                          final user = supabase.auth.currentUser;

                          if (user != null) {
                            supabase
                                .from('users')
                                .select('role')
                                .eq('id', user.id)
                                .maybeSingle()
                                .then((userData) {
                              final role = userData?['role'] ?? 'customer';
                              if (mounted) {
                                if (role == 'provider') {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ProviderDashboard()),
                                  );
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CustomerHome()),
                                  );
                                }
                              }
                            });
                          } else {
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const CustomerHome()),
                              );
                            }
                          }
                          viewModel.resetState();
                        });
                      }

                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: state is CustomerLoginLoading
                              ? null
                              : () {
                            viewModel.login(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: state is CustomerLoginLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('LOGIN', style: TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomerSignupScreen()),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Are you a provider?'),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProviderLogin()),
                        ),
                        child: const Text(
                          'Login as Provider',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}