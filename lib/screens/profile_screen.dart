import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import 'profile_edit_sheet.dart';
import 'login_screen.dart';
import 'dart:html' as html if (dart.library.html) 'dart:html';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(0);

  // ----------------------------------------------------------------------
  void _openEditSheet(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final user = appProvider.user;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfileEditSheet(
        userName: user?.nom ?? '',
        userEmail: user?.email ?? '',
        onSave: (name, email, password, imageUrl) async {
          try {
            User? updated;
            if (imageUrl != null) {
              updated = await appProvider.updateCurrentUser(
                nom: name,
                email: email,
                imageUrl: imageUrl,
              );
            } else {
              updated = await appProvider.updateCurrentUser(
                nom: name,
                email: email,
              );
            }

            if (updated != null && context.mounted) {
              Navigator.pop(ctx);
              _refreshNotifier.value++;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil mis à jour avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erreur lors de la mise à jour'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur : $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  // ----------------------------------------------------------------------
  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).logout();
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Déconnexion effectuée'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _refreshNotifier,
      builder: (context, _, __) {
        final appProvider = Provider.of<AppProvider>(context);
        final user = appProvider.user;

        final hasImage = user?.imageUrl != null && user!.imageUrl!.isNotEmpty;

        if (appProvider.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFfcf9f8),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFfcf9f8),
            body: Center(child: Text('Aucun utilisateur trouvé')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.green.shade50,
          appBar: null,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: hasImage
                              ? ClipOval(
                                  child: Image.network(
                                    user.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: 90,
                                    height: 90,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF4caf50),
                                      child: const Icon(Icons.person,
                                          size: 48, color: Colors.white),
                                    ),
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4caf50),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person,
                                      size: 48, color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          user.nom,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1b1c1c),
                            letterSpacing: -0.01,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFdee5d6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            user.email,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF42493e),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openEditSheet(context),
                            icon: const Icon(Icons.settings, size: 20),
                            label: const Text('Paramètres du profil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4caf50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              textStyle: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _logout(context),
                            icon: const Icon(Icons.power_settings_new,
                                size: 20, color: Color(0xFFba1a1a)),
                            label: const Text('Déconnexion',
                                style: TextStyle(color: Color(0xFFba1a1a))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFe5e2e1), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              textStyle: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}