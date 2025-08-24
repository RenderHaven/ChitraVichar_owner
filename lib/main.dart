import 'package:chitraowner/ApiManagment/ProductApi.dart';
import 'package:chitraowner/Tools.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'HomePage.dart';
void main() async{
  
  runApp(const MyApp());
  await Supabase.initialize(
    url: 'https://otbodiyxtuwohiwhvhps.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90Ym9kaXl4dHV3b2hpd2h2aHBzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MDEwMDEsImV4cCI6MjA2NTM3NzAwMX0.8gUy65rFvXNICpcmHm-19KWbhgJwY5yQPo7D-onJ9k8',
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChitraVichar Owner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isCheckingAuth = false; // For submit button loading state

  @override
  void initState() {
    super.initState();
    _checkAuthKey();
  }

  Future<void> _checkAuthKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('auth_key');

    if (savedKey != null && await HomeApi.validateKey(savedKey)) {
      setState(() {
        _isAuthenticated = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showAuthDialog(prefs);
      }
    }
  }

  void _showAuthDialog(SharedPreferences prefs) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your auth key',
                  prefixIcon: const Icon(Icons.key),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a key' : null,
              ),
              const SizedBox(height: 16),
              if (_isCheckingAuth)
                const CircularProgressIndicator(),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: _isCheckingAuth
                ? null
                : () async {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() => _isCheckingAuth = true);
                      
                      final key = controller.text.trim();
                      final isValid = await HomeApi.validateKey(key);
                      
                      if (mounted) {
                        if (isValid) {
                          await prefs.setString('auth_key', key);
                          setState(() => _isAuthenticated = true);
                          Navigator.of(context).pop();
                        } else {
                          Homepage.showOverlayMessage(context, 'Invalid auth key');
                        }
                        setState(() => _isCheckingAuth = false);
                      }
                    }
                  },
            child: const Text('Continue'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ).then((_) {
      if (!_isAuthenticated) {
        // If dialog closed without successful auth, show again
        _showAuthDialog(prefs);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking authentication...'),
            ],
          ),
        ),
      );
    }

    return _isAuthenticated 
        ? Homepage()
        : Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.orange),
                  const SizedBox(height: 24),
                  Text(
                    'Authentication Required',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text('Please wait while we load the authentication screen...'),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
  }
}