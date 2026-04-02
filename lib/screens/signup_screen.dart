import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🌟 Import Firebase Auth Manager
import '../main.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // 🌟 Core killer: Real Firebase registration logic
  Future<void> _handleSignUp() async {
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ ALL FIELDS REQUIRED!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 1. Send registration request to Firebase!
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Save the username entered by the user into his cloud profile
      await userCredential.user?.updateDisplayName(_usernameController.text.trim());

      // 3. Registration successful, allow entry into the main system!
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigator()),
          (route) => false, 
        );
      }
    } on FirebaseAuthException catch (e) {
      // If there's an error (e.g., password too short, email format wrong), show popup with real reason
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ERROR: ${e.message}'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF00E5FF),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "CREATE\nENTITY_.",
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Register your EcoFix ID.",
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 40),

              _buildCyberTextField("USERNAME (ALIAS)", Icons.person_outline, _usernameController),
              const SizedBox(height: 20),
              _buildCyberTextField("EMAIL IDENTIFIER", Icons.email_outlined, _emailController),
              const SizedBox(height: 20),
              _buildCyberTextField("ACCESS KEY (PASSWORD)", Icons.lock_outline, _passwordController, isPassword: true),
              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text("INITIALIZE REGISTRATION", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
            prefixIcon: Icon(icon, color: Colors.purpleAccent),
            filled: true,
            fillColor: const Color(0xFF1A212E),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blueGrey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}