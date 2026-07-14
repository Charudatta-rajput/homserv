import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:homserv/presentation/auth/login/customer_login_screen.dart';
import 'package:homserv/presentation/auth/login/provider_login_screen.dart';
import 'package:homserv/presentation/auth/signup/customer_signup_screen.dart';
import 'package:homserv/presentation/auth/signup/provider_signup_screen.dart';
import 'package:homserv/presentation/customer/home/customer_home.dart';
import 'package:homserv/presentation/customer/services/service_screen.dart';
import 'package:homserv/presentation/customer/providers/provider_list_screen.dart';
import 'package:homserv/presentation/customer/bookings/my_bookings_screen.dart';
import 'package:homserv/presentation/provider/dashboard/provider_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();

  FirebaseMessaging.onMessage.listen((message) {
    NotificationService.showLocalNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    print('📱 Opened from notification: ${message.data}');
  });

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
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/customer-login': (context) => const CustomerLoginScreen(),
        '/provider-login': (context) => const ProviderLogin(),
        '/customer-signup': (context) => const CustomerSignupScreen(),
        '/provider-signup': (context) => const ProviderSignupScreen(),
        '/customer-home': (context) => const CustomerHome(),
        '/provider-dashboard': (context) => const ProviderDashboard(),
        '/services': (context) => const ServicesScreen(),
        '/my-bookings': (context) => const MyBookingsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (!mounted) return;

    if (session != null) {
      try {
        final userData = await supabase
            .from('users')
            .select('role')
            .eq('id', session.user.id)
            .maybeSingle();

        final role = userData?['role'] ?? 'customer';

        if (!mounted) return;

        if (role == 'provider') {
          Navigator.pushReplacementNamed(context, '/provider-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/customer-home');
        }
      } catch (e) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/customer-login');
        }
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/customer-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home_repair_service,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'HomServ',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Home Services Platform',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}