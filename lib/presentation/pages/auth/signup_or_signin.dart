import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mymusicplayer_new/presentation/pages/admin/admin_dashboard.dart';
import 'package:mymusicplayer_new/core/configs/admin_config.dart';
import 'package:mymusicplayer_new/common/widget/button/basic_app_button.dart';
import 'package:mymusicplayer_new/core/configs/assets/app_images.dart';
import 'package:mymusicplayer_new/core/configs/assets/app_vectors.dart';
import 'package:mymusicplayer_new/presentation/pages/auth/register_page.dart';
import 'package:mymusicplayer_new/presentation/pages/auth/signin_page.dart';

class SignupOrSignin extends StatefulWidget {
  const SignupOrSignin({super.key});

  @override
  State<SignupOrSignin> createState() => _SignupOrSigninState();
}

class _SignupOrSigninState extends State<SignupOrSignin> {

  // 🔐 ADMIN LOGIN DIALOG
  void _showAdminLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Admin Login',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Admin Email',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                // backgroundColor: Colors.orangeAccent,
              ),
              onPressed: () {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                if (AdminConfig.isValidAdmin(email, password)) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminDashboard(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Invalid admin credentials'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🎵 Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImages.authBG),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🌫 Dark Overlay
          Container(color: Colors.black.withOpacity(0.6)),

          // 🌟 Glass UI Card
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔊 Logo
                      SvgPicture.asset(
                        AppVectors.logo,
                        width: 220,
                      ),

                      const SizedBox(height: 20),

                      // 🎶 Title
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(text: 'Enjoy Listening To\n'),
                            TextSpan(
                              text: 'Jovial Music',
                              style: TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 30,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'A smooth and joyful music streaming experience',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 🔘 Auth Buttons
                      Row(
                        children: [
                          Expanded(
                            child: BasicAppButton(
                              title: 'Register',
                              backgroundColor: Colors.yellowAccent,
                              textColor: Colors.black,
                              height: 48,
                              borderRadius: 14,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SignupPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: BasicAppButton(
                              title: 'Sign In',
                              backgroundColor: Colors.white,
                              textColor: Colors.black,
                              height: 48,
                              borderRadius: 14,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SigninPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),
                      const Divider(color: Colors.white24),

                      // 🔐 Admin Dashboard Button
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: Colors.black.withOpacity(0.4),
                        leading: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.orangeAccent,
                          size: 28,
                        ),
                        title: const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Upload & manage songs',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white54,
                          size: 16,
                        ),
                        onTap: _showAdminLoginDialog,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
