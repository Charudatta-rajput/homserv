import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/notification_service.dart';
import 'provider_login_viewmodel.dart';
import 'provider_login_state.dart';
import '../signup/provider_signup_screen.dart';
import '../../provider/dashboard/provider_dashboard.dart';
import '../login/customer_login_screen.dart';


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
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'Provider Login',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
              );
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Consumer<ProviderLoginViewModel>(
              builder: (context, viewModel, child) {
                final state = viewModel.state;

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

                if (state is ProviderLoginSuccess) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (state.verificationStatus == 'pending') {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Verification Pending',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            'Your account is waiting for admin approval. '
                                'You will be notified once verified.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                await Supabase.instance.client.auth.signOut();
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      viewModel.resetState();
                    } else if (state.verificationStatus == 'approved') {
                      final token = await NotificationService.getFCMToken();
                      if (token != null) {
                        await Supabase.instance.client
                            .from('user_devices')
                            .upsert({
                          'user_id': state.userId,
                          'fcm_token': token,
                        }, onConflict: 'fcm_token');
                      }
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Verification Rejected',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            'Your application has been rejected. '
                                'Please contact support for more information.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                await Supabase.instance.client.auth.signOut();
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      viewModel.resetState();
                    } else {
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.work,
                        size: 50,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Provider Login',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Login to manage your services',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 40),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF10B981),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF10B981),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
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
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: state is ProviderLoginLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProviderSignupScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                          ),
                          child: const Text(
                            'Register as Provider',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Are you a customer?',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerLoginScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                          ),
                          child: const Text(
                            'Customer Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
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