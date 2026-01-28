import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mymusicplayer_new/presentation/pages/auth/signup_or_signin.dart';
import 'package:mymusicplayer_new/presentation/pages/profile/settings_page.dart';
import 'package:mymusicplayer_new/presentation/pages/profile/whats_new_page.dart';
import 'package:mymusicplayer_new/core/theme/theme_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mymusicplayer_new/services/audio_player_service.dart';
import 'package:mymusicplayer_new/presentation/widgets/mini_player.dart';
import '../music_player/music_player_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
  File? _imageFile;
  bool _isLoading = true;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedImage();
  }

  Future<void> _loadUserData() async {
    // Reload user data from Firebase to get latest updates
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
  }

  Future<void> _loadSavedImage() async {
    if (kIsWeb) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final imageName = prefs.getString('profile_image_name');
      if (imageName != null && imageName.isNotEmpty) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$imageName');
        if (!kIsWeb && await file.exists()) {
          setState(() => _imageFile = file);
        }
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveImagePermanently(File sourceFile) async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo saving is not supported on Web.'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)),
        );
      }
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageName = 'profile_${user?.uid ?? 'user'}.jpg';
      final savedPath = '${directory.path}/$imageName';
      final savedImage = await sourceFile.copy(savedPath);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_name', imageName);
      setState(() => _imageFile = savedImage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo saved successfully!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save photo. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final imageName = prefs.getString('profile_image_name');
      if (imageName != null) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$imageName');
        if (await file.exists()) await file.delete();
        await prefs.remove('profile_image_name');
      }
      setState(() => _imageFile = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo removed'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  String getInitial() {
    String name = getDisplayName();
    return name.isNotEmpty ? name[0].toUpperCase() : "U";
  }

  String extractNameFromEmail(String email) {
    if (email.isEmpty) return "Guest";
    String username = email.split('@')[0];
    username = username.replaceAll(RegExp(r'[0-9]'), '');
    username = username.replaceAll('_', ' ').replaceAll('.', ' ');
    username = username.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    List<String> words = username.split(' ').where((e) => e.isNotEmpty).toList();
    return words.map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }

  String getDisplayName() {
    if (user == null) return "Unknown User";
    // First check if displayName is set
    if (user!.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!;
    }
    // Otherwise extract from email
    return extractNameFromEmail(user!.email ?? "");
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
        _lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2);

    if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _showImagePickerSheet,
                          child: Stack(
                            children: [
                              _isLoading
                                  ? const CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.purple,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.purple,
                                backgroundImage: (!kIsWeb && _imageFile != null)
                                    ? FileImage(_imageFile!)
                                    : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : (kIsWeb && _imageFile != null ? NetworkImage(_imageFile!.path) : null)) as ImageProvider?,
                                child: ((!kIsWeb && _imageFile == null && user?.photoURL == null) || (kIsWeb && _imageFile == null && user?.photoURL == null))
                                    ? Text(getInitial(), style: const TextStyle(fontSize: 24, color: Colors.white))
                                    : null,
                              ),
                              if (!_isLoading)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                                )
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(getDisplayName(),
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.yellow : Colors.orange)),
                              const SizedBox(height: 4),
                              Text(user?.email ?? "No email", style: TextStyle(fontSize: 14, color: isDark ? Colors.grey : Colors.grey[600])),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildMenuItem(
                      icon: Icons.flash_on,
                      title: "What's new",
                      subtitle: "Check latest updates",
                      isDark: isDark,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhatsNewPage())),
                    ),
                    _buildMenuItem(
                      icon: Icons.settings,
                      title: "Settings and privacy",
                      subtitle: "Manage your account",
                      isDark: isDark,
                      onTap: () async {
                        // Navigate to settings and reload user data when returning
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                        // Refresh user data after returning from settings
                        await _loadUserData();
                      },
                    ),
                    const Spacer(),
                    Center(
                      child: TextButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text("Logout", style: TextStyle(color: Colors.red, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? Colors.white24 : Colors.grey[300]),
                    Center(
                      child: Text("Music Player App v1.0",
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 12)),
                    ),
                    Center(
                      child: Text("Built by - Harshit",
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
          ],
        ),
      ),
    );
  }

  void _showImagePickerSheet() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Profile Photo',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.purple),
              title: Text("Choose from Gallery", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  if (kIsWeb) {
                    setState(() {
                      _imageFile = File(picked.path);
                    });
                  } else {
                    await _saveImagePermanently(File(picked.path));
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.purple),
              title: Text("Take a Photo", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                if (picked != null) {
                  if (kIsWeb) {
                    setState(() {
                      _imageFile = File(picked.path);
                    });
                  } else {
                    await _saveImagePermanently(File(picked.path));
                  }
                }
              },
            ),
            if (_imageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text("Remove Photo", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteProfileImage();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await GlobalMusicPlayer.instance.audioPlayer.stop();
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    final imageName = prefs.getString('profile_image_name');
    await prefs.clear();
    if (imageName != null) await prefs.setString('profile_image_name', imageName);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignupOrSignin()), (_) => false);
  }

  Widget _buildMenuItem({required IconData icon, required String title, String? subtitle, required bool isDark, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isDark ? Colors.white : Colors.black),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        subtitle:
        subtitle != null ? Text(subtitle, style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600], fontSize: 12)) : null,
        trailing: Icon(Icons.arrow_forward_ios, color: isDark ? Colors.grey : Colors.grey[600], size: 16),
        onTap: onTap,
      ),
    );
  }
}