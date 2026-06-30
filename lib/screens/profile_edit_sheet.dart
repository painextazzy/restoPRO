import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cloudinary_service.dart';

// Import conditionnel pour le web
import 'dart:html' as html if (dart.library.html) 'dart:html';

class ProfileEditSheet extends StatefulWidget {
  final String userName;
  final String userEmail;
  final Future<void> Function(
    String name,
    String email,
    String password,
    String? imageUrl, // ✅ URL Cloudinary
  ) onSave;

  const ProfileEditSheet({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onSave,
  });

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _imagePreviewUrl;
  String? _uploadedImageUrl; // ✅ URL Cloudinary
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.userEmail);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // SÉLECTION D'IMAGE
  // ------------------------------------------------------------
  Future<void> _pickImage() async {
    if (kIsWeb) {
      await _pickImageWeb();
    } else {
      await _pickImageMobile();
    }
  }

  Future<void> _uploadToCloudinary(Uint8List bytes, String fileName) async {
    setState(() => _isUploading = true);
    try {
      final url = await CloudinaryService.uploadImage(
        bytes,
        fileName,
        folder: 'profiles',
      );
      setState(() {
        _uploadedImageUrl = url;
        _isUploading = false;
      });
      print('✅ Image uploadée vers Cloudinary: $url');
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur upload : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageWeb() async {
    try {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      await input.onChange.first;

      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;

        final bytes = reader.result as Uint8List?;
        if (bytes != null) {
          setState(() {
            _imageBytes = bytes;
            _imageFileName = file.name;
            _imagePreviewUrl = html.Url.createObjectUrl(file);
          });
          await _uploadToCloudinary(bytes, file.name);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageMobile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null) {
        final platformFile = result.files.single;
        final bytes = platformFile.bytes;
        if (bytes != null) {
          setState(() {
            _imageBytes = bytes;
            _imageFileName = platformFile.name;
            _imagePreviewUrl = null;
          });
          await _uploadToCloudinary(bytes, platformFile.name);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // SAUVEGARDE
  // ------------------------------------------------------------
  void _save() async {
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await widget.onSave(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _uploadedImageUrl, // ✅ URL Cloudinary
    );

    if (mounted) setState(() => _isLoading = false);
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final hasImage = _imagePreviewUrl != null || _imageBytes != null;

    return Container(
      height: screenHeight * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFFfcf9f8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFbecab9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Center(
              child: Text(
                'Modifier le profil',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1b1c1c),
                  letterSpacing: -0.01,
                ),
              ),
            ),
          ),
          const Divider(color: Color(0xFFbecab9), height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: bottomPadding + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upload de photo
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFbecab9).withOpacity(0.5),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        image: hasImage
                            ? DecorationImage(
                                image: _imagePreviewUrl != null
                                    ? NetworkImage(_imagePreviewUrl!)
                                    : (_imageBytes != null
                                        ? MemoryImage(_imageBytes!)
                                        : null as ImageProvider),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _isUploading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : hasImage
                              ? Stack(
                                  children: [
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Changer',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ajouter une photo',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1b1c1c),
                                      ),
                                    ),
                                    Text(
                                      'Cliquez pour sélectionner',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF6f7a6b),
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  if (_uploadedImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '✅ Image uploadée',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    label: 'Nom',
                    controller: _nameController,
                    hint: 'Votre nom',
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'E-mail',
                    controller: _emailController,
                    hint: 'email@exemple.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Nouveau mot de passe',
                    controller: _passwordController,
                    hint: '••••••••',
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Confirmation du mot de passe',
                    controller: _confirmPasswordController,
                    hint: '••••••••',
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isUploading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4caf50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isLoading || _isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF3f4a3c),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFbecab9),
            ),
            filled: true,
            fillColor: const Color(0xFFf6f3f2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFbecab9),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFbecab9).withOpacity(0.4),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4caf50),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1b1c1c),
          ),
        ),
      ],
    );
  }
}