import 'package:mymusicplayer_new/core/configs/assets/app_vectors.dart';
import 'package:mymusicplayer_new/core/configs/usecase/auth/signin.dart';
import 'package:mymusicplayer_new/data/models/auth/signin_user_req.dart';
import 'package:mymusicplayer_new/main.dart';
import 'package:mymusicplayer_new/core/service_locator.dart';
import 'package:mymusicplayer_new/presentation/pages/auth/register_page.dart';
import 'package:mymusicplayer_new/presentation/pages/admin/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ added

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: _signinFooter(context),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: SvgPicture.asset(
          AppVectors.logo,
          height: 100,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              "Sign In",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            _buildTextField(_email, 'Enter Email', false),
            const SizedBox(height: 30),
            _buildTextField(_password, 'Password', true),
            const SizedBox(height: 40),

            // 🌟 Glowing "Sign In" button
            Center(
              child: GestureDetector(
                onTap: _handleSignin,
                child: Container(
                  width: 200,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.yellowAccent, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.yellowAccent,
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Sign In",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.yellow, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _signinFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Don't have an account?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => SignupPage()),
              );
            },
            child: const Text(
              "Register Now",
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignin() async {
    final result = await sl<SigninUseCase>().call(
      params: SigninUserReq(
        email: _email.text.trim(),
        password: _password.text.trim(),
      ),
    );

    result.fold(
          (l) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l)),
        );
      },
          (r) async {
        try {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId == null) throw Exception("No user ID found after sign in.");

          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          final role = doc.data()?['role']?.toString().toLowerCase() ?? 'user';

          // ✅ Save login state persistently
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("isLoggedIn", true);

          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PlayerPage()),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e')),
          );
        }
      },
    );
  }
}
