import 'package:mymusicplayer_new/core/configs/assets/app_vectors.dart';
import 'package:mymusicplayer_new/core/configs/usecase/auth/signup.dart';
import 'package:mymusicplayer_new/data/models/auth/create_user_req.dart';
import 'package:mymusicplayer_new/helpers/widget/appbar/app_bar.dart';
import 'package:mymusicplayer_new/core/service_locator.dart';
import 'package:mymusicplayer_new/presentation/pages/auth/signin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: _signupText(context),
      appBar: BasicAppBar(
        title: SvgPicture.asset(
          AppVectors.logo,
          width: 100,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _registerText(),
            const SizedBox(height: 40),
            _customTextField(_fullName, 'Full Name'),
            const SizedBox(height: 30),
            _customTextField(_email, 'Enter Email'),
            const SizedBox(height: 30),
            _customTextField(_password, 'Password', isPassword: true),
            const SizedBox(height: 30),
            _customTextField(_confirmPassword, 'Confirm Password', isPassword: true),
            const SizedBox(height: 40),
            _glowingButton(),
          ],
        ),
      ),
    );
  }

  Widget _registerText() {
    return const Text(
      'Register',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 26,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _customTextField(TextEditingController controller, String hint,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.yellow.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.yellow, width: 2),
        ),
      ),
    );
  }

  Widget _glowingButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.8),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: () async {
          if (_password.text.trim() != _confirmPassword.text.trim()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passwords do not match')),
            );
            return;
          }

          var result = await sl<SignupUseCase>().call(
            params: CreateUserReq(
              fullName: _fullName.text.trim(),
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
                // Get the current user from FirebaseAuth instead of relying on the result
                User? currentUser = FirebaseAuth.instance.currentUser;

                if (currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .set({
                    'fullName': _fullName.text.trim(),
                    'email': _email.text.trim(),
                    'role': 'user',
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const SigninPage()),
                          (route) => false,
                    );
                  }
                } else {
                  throw Exception('User authentication failed');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Firestore Error: $e')),
                  );
                }
              }
            },
          );
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E),
          side: const BorderSide(color: Colors.yellow, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        ),
        child: const Text(
          'Create Account',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _signupText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Already have an account?',
            style: TextStyle(fontSize: 20, color: Colors.white,fontWeight: FontWeight.bold,),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SigninPage()),
                    (route) => false,
              );
            },
            child: const Text(
              'Sign in',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}