import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';
import '../services/cloudinary_service.dart'; // ✅ Nouveau service
import '../widgets/success_dialog.dart';

// Pour le Web
import 'dart:html' as html;

class AddMenuItemScreen extends StatefulWidget {
  final MenuItem? menuItem;

  const AddMenuItemScreen({super.key, this.menuItem});

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  final _quantiteController = TextEditingController();
  String _selectedCategorie = 'PLAT';
  bool _isLoading = false;

  // Image : soit bytes (nouvelle sélection), soit URL existante
  Uint8List? _imageBytes;
  String? _imageFileName;
  String?
      _imagePreviewUrl; // pour l'aperçu local (Web) ou URL Cloudinary existante
  bool _hasNewImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.menuItem != null) {
      _nomController.text = widget.menuItem!.nom;
      _descriptionController.text = widget.menuItem!.description ?? '';
      _prixController.text = widget.menuItem!.prix.toString();
      _quantiteController.text = widget.menuItem!.quantite.toString();
      _selectedCategorie = widget.menuItem!.categorie;
      // Si l'article a une image (URL Cloudinary), on l'affiche
      if (widget.menuItem!.imageUrl != null &&
          widget.menuItem!.imageUrl!.isNotEmpty) {
        _imagePreviewUrl = widget.menuItem!.imageUrl;
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _quantiteController.dispose();
    super.dispose();
  }

  // ==========================================
  // SÉLECTION D'IMAGE (Web + Mobile)
  // ==========================================
  Future<void> _pickImage() async {
    // Détection de la plateforme
    if (html.window != null) {
      await _pickImageWeb();
    } else {
      await _pickImageMobile();
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
            _hasNewImage = true;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
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
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          setState(() {
            _imageBytes = bytes;
            _imageFileName = result.files.single.name;
            _imagePreviewUrl = null;
            _hasNewImage = true;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ==========================================
  // VALIDATEURS (inchangés)
  // ==========================================

  String? _validateNom(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le nom est requis';
    final trimmed = value.trim();
    final regex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-\.']+$");
    if (!regex.hasMatch(trimmed))
      return 'Caractères spéciaux ou chiffres non autorisés';
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'La description est requise';
    final trimmed = value.trim();
    final regex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-\.\,\'\(\)]+$");
    if (!regex.hasMatch(trimmed))
      return 'Caractères spéciaux ou chiffres non autorisés';
    return null;
  }

  String? _validatePrix(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le prix est requis';
    final trimmed = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed))
      return 'Le prix doit être un nombre entier (ex: 10000)';
    final int prix = int.parse(trimmed);
    if (prix < 1000 || prix > 99999)
      return 'Le prix doit être entre 1000 et 99999 (4 à 5 chiffres)';
    return null;
  }

  String? _validateQuantite(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le stock est requis';
    final trimmed = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed))
      return 'Le stock doit être un nombre entier';
    final int qte = int.parse(trimmed);
    if (qte < 1) return 'Le stock doit être ≥ 1';
    return null;
  }

  // ==========================================
  // ENREGISTREMENT AVEC CLOUDINARY
  // ==========================================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nom = _nomController.text.trim();
      final description = _descriptionController.text.trim();
      final prix = int.parse(_prixController.text.trim()).toDouble();
      final quantite = int.parse(_quantiteController.text.trim());
      final categorie = _selectedCategorie;

      // 1. Upload vers Cloudinary si une nouvelle image a été sélectionnée
      String? imageUrl;
      if (_imageBytes != null && _hasNewImage) {
        imageUrl = await CloudinaryService.uploadImage(
          _imageBytes!,
          _imageFileName ?? 'image.jpg',
          folder: 'menu',
        );
      } else {
        // Si pas de nouvelle image, on garde l'ancienne URL (si existante)
        imageUrl = widget.menuItem?.imageUrl;
      }

      // 2. Préparer les données pour le backend
      final Map<String, dynamic> data = {
        'nom': nom,
        'description': description,
        'prix': prix,
        'quantite': quantite,
        'categorie': categorie,
      };
      if (imageUrl != null) {
        data['image_url'] = imageUrl;
      }

      // 3. Appel à l'API (création ou mise à jour)
      if (widget.menuItem == null) {
        await ApiService.createMenuItem(data);
      } else {
        await ApiService.updateMenuItem(widget.menuItem!.id, data);
      }

      if (!mounted) return;

      // ✅ Succès
      SuccessDialog.show(
        context,
        title: widget.menuItem == null ? 'Ajouté' : 'Modifié',
        message: widget.menuItem == null
            ? 'L\'article a été ajouté avec succès.'
            : 'L\'article a été modifié avec succès.',
        onDismiss: () {
          if (mounted) Navigator.pop(context, true);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // BUILD (inchangé, sauf la gestion de l'image)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final hasImage =
        _imagePreviewUrl != null || (_imageBytes != null && _hasNewImage);

    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1b1c1c)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.menuItem == null ? 'Ajouter un plat' : 'Modifier un plat',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1b1c1c),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageUpload(hasImage),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Nom du plat',
                    controller: _nomController,
                    hint: 'Ex: Pizza Pepperoni',
                    validator: _validateNom,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Description',
                    controller: _descriptionController,
                    hint: 'Décrivez les ingrédients...',
                    validator: _validateDescription,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Prix (Ar)',
                    controller: _prixController,
                    hint: 'Ex: 10000',
                    validator: _validatePrix,
                    keyboardType: TextInputType.number,
                    suffix: 'Ar',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Quantité',
                    controller: _quantiteController,
                    hint: 'Stock disponible',
                    validator: _validateQuantite,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf0eded),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF006e1c), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ce plat sera immédiatement visible sur l\'application client une fois enregistré.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF3f4a3c),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _save,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle, size: 22),
                    label: Text(
                      _isLoading
                          ? 'Enregistrement...'
                          : widget.menuItem == null
                              ? 'Enregistrer le produit'
                              : 'Modifier le produit',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006e1c),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGETS DU FORMULAIRE
  // ==========================================

  Widget _buildImageUpload(bool hasImage) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFeae7e7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFbecab9).withOpacity(0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
          image: hasImage
              ? DecorationImage(
                  image: _imageBytes != null && _hasNewImage
                      ? MemoryImage(_imageBytes!)
                      : (_imagePreviewUrl != null
                          ? NetworkImage(_imagePreviewUrl!)
                          : null as ImageProvider),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasImage
            ? Stack(
                children: [
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Changer la photo',
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
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4caf50).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Color(0xFF006e1c),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ajouter une photo',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1b1c1c),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cliquez pour sélectionner une image',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6f7a6b),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? suffix,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFbecab9),
            ),
            suffixText: suffix,
            suffixStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF3f4a3c),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFbecab9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: const Color(0xFFbecab9).withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4caf50), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1b1c1c),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = ['ENTREE', 'PLAT', 'BOISSON', 'DESSERT'];
    final labels = {
      'ENTREE': 'Entrée',
      'PLAT': 'Plat',
      'BOISSON': 'Boisson',
      'DESSERT': 'Dessert',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF3f4a3c),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFbecab9).withOpacity(0.5)),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategorie,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.expand_more, color: Color(0xFF6f7a6b)),
            items: categories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(
                  labels[cat] ?? cat,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF1b1c1c),
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategorie = value!),
            validator: (value) => value == null ? 'Requis' : null,
          ),
        ),
      ],
    );
  }
}
