import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import generated firebase options
import 'firebase_options.dart';

// Import all required pages
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/dashboard.dart'; // Now acts as unified Home/Dashboard
import 'pages/add_expense_page.dart';
import 'pages/ai_result_page.dart';
import 'pages/add_income_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // ✅ Initialize Firebase with configuration
  runApp(const MyApp()); // ✅ Run App
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Personal Finance Coach',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,

      // ✅ Start app based on login state
      home: const AuthWrapper(),

      // ✅ Define named routes for easy navigation
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) =>
            const DashboardPage(), // Unified Home/Dashboard
        '/add-expense': (context) => const AddExpensePage(), // Add Expense Page
        '/add-income': (context) => const AddIncomePage(),
        '/ai-result': (context) => const AIResultPage(), // AI Suggestion Page
      },
    );
  }
}

// ✅ Wrapper widget to check if user is logged in or not
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Firebase Auth Stream
      builder: (context, snapshot) {
        // ✅ Show loading indicator while checking login state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // ✅ If user is logged in, show Dashboard
        else if (snapshot.hasData) {
          return const DashboardPage();
        }
        // ✅ If not logged in, show Login Page
        else {
          return const LoginPage();
        }
      },
    );
  }
}
