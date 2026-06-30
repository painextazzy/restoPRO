import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/table.dart';
import '../providers/app_provider.dart';
import '../widgets/success_dialog.dart';

class AddTableSheet extends StatefulWidget {
  final VoidCallback onSaved;

  const AddTableSheet({super.key, required this.onSaved});

  @override
  State<AddTableSheet> createState() => _AddTableSheetState();
}

class _AddTableSheetState extends State<AddTableSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _capaciteController = TextEditingController();
  String _forme = 'rond';
  bool _isLoading = false;

  @override
  void dispose() {
    _numeroController.dispose();
    _capaciteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final numero = int.parse(_numeroController.text.trim());
      final capacite = int.parse(_capaciteController.text.trim());
      final forme = _forme;
      final appProvider = context.read<AppProvider>();

      // Vérifier si le numéro existe déjà
      final existing = appProvider.tables.any((table) {
        final numParts = table.nom.split(' ');
        final tableNum =
            numParts.length > 1 ? int.tryParse(numParts.last) : null;
        return tableNum == numero;
      });

      if (existing) {
        throw Exception('Une table avec le numéro $numero existe déjà');
      }

      final newTable = TableModel(
        id: 0,
        nom: 'Table $numero',
        capacite: capacite,
        status: 'LIBRE',
        posX: 0.5,
        posY: 0.5,
        forme: forme,
      );
      await appProvider.createTable(newTable);
      widget.onSaved();

      if (mounted) {
        SuccessDialog.show(
          context,
          title: 'Ajoutée',
          message: 'La table a été ajoutée avec succès.',
          onDismiss: () {
            if (mounted) Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erreur : ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Retour direct du Container, sans Scaffold
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFbecab9),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Center(
              child: Text(
                'Nouvelle table',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1b1c1c),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Numéro table',
                      controller: _numeroController,
                      hint: '1',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (int.tryParse(v) == null) return 'Nombre entier';
                        final val = int.parse(v);
                        if (val < 1 || val > 10) return 'Entre 1 et 10';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Capacité',
                      controller: _capaciteController,
                      hint: '4',
                      keyboardType: TextInputType.number,
                      suffixIcon:
                          const Icon(Icons.people, color: Color(0xFF6f7a6b)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (int.tryParse(v) == null) return 'Nombre entier';
                        final val = int.parse(v);
                        if (val < 1 || val > 10) return 'Entre 1 et 10';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDropdown(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFbecab9), width: 0.5),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006e1c),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        )
                      : Text(
                          'Ajouter la table',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
  // WIDGETS DU FORMULAIRE (inchangés)
  // ==========================================

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3f4a3c),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFbecab9),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFf6f3f2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFFbecab9), width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: const Color(0xFFbecab9).withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4caf50), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1b1c1c),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    final items = [
      {'value': 'rond', 'label': 'Ronde'},
      {'value': 'carre', 'label': 'Carrée'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forme',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3f4a3c),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFf6f3f2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFbecab9).withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _forme,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.expand_more, color: Color(0xFF6f7a6b)),
            dropdownColor: Colors.white,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item['value'],
                child: Text(
                  item['label']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF1b1c1c),
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _forme = value!),
            validator: (value) => value == null ? 'Requis' : null,
          ),
        ),
      ],
    );
  }
}
