import 'package:flutter/material.dart';
import 'package:homserv/presentation/auth/login/customer_login_screen.dart';
import 'package:homserv/presentation/auth/login/provider_login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'presentation/customer/home/customer_home.dart';
import 'presentation/provider/dashboard/provider_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomServ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/customer-login',
      routes: {
        '/customer-login': (context) => const CustomerLoginScreen(),
        '/provider-login': (context) => const ProviderLogin(),
        '/customer-home': (context) => const CustomerHome(),
        '/provider-dashboard': (context) => const ProviderDashboard(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}