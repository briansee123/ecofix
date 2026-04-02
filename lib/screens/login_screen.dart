import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../main.dart'; 
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // 🌟 Core Kill: Real Firebase Login Logic
  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ CREDENTIALS REQUIRED!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() { _isLoading = true; });
    
    try {
      // Take the email and password to knock on Firebase cloud door!
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Verification passed, allow entry to main system!
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigator()), 
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Wrong password or account doesn't exist, alarm!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ACCESS DENIED: ${e.message}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      // 🌟 Ultimate catch-all: Catch all mysterious system crash errors!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ SYSTEM ERROR: $e'), backgroundColor: Colors.orange, duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _enterGuestMode() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigator()), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Cyberpunk deep black background color
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "SYSTEM\nONLINE_.",
                style: TextStyle(
                  color: Color(0xFF00E5FF), 
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Welcome to EcoFix Network.",
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 50),

              _buildCyberTextField("EMAIL IDENTIFIER", Icons.email_outlined, _emailController),
              const SizedBox(height: 20),
              _buildCyberTextField("ACCESS KEY (PASSWORD)", Icons.lock_outline, _passwordController, isPassword: true),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                      : const Text("INITIALIZE LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 15),
              
              Center(
                child: TextButton(
                  onPressed: () {
                    // Fly to registration page!
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  child: const Text("NEW USER? CREATE ACCOUNT", style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              
              const SizedBox(height: 30),
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _enterGuestMode,
                  icon: const Icon(Icons.public, color: Colors.greenAccent),
                  label: const Text("ENTER AS GUEST", style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.greenAccent, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCyberTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF00E5FF)),
            filled: true,
            fillColor: const Color(0xFF1A212E),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blueGrey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}