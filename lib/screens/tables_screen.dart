import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../models/table.dart';
import 'add_table_sheet.dart';
import 'edit_table_sheet.dart';
import '../widgets/success_dialog.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'TOUS';
  late final ValueNotifier<int> _tableNotifier;
  // Polling de secours (optionnel)
  // late final Timer _pollingTimer;

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    _tableNotifier = appProvider.tableChangeNotifier;
    _tableNotifier.addListener(_onTableChanged);

    // Polling de secours si WebSocket est instable (désactivable)
    // _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
    //   if (mounted) {
    //     final provider = Provider.of<AppProvider>(context, listen: false);
    //     provider.loadTables();
    //   }
    // });
  }

  void _onTableChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tableNotifier.removeListener(_onTableChanged);
    // _pollingTimer.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------
  // Filtrage des tables
  // ------------------------------------------------------------
  List<TableModel> _getFilteredTables(AppProvider appProvider) {
    return appProvider.tables.where((t) {
      bool matchSearch =
          t.nom.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchFilter = _selectedFilter == 'TOUS' ||
          (_selectedFilter == 'LIBRE' && t.isAvailable) ||
          (_selectedFilter == 'OCCUPEE' && t.isOccupied);
      return matchSearch && matchFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final tables = _getFilteredTables(appProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        actions: const [],
      ),
      body: appProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBarWithFilter(),
                const SizedBox(height: 12),
                _buildLegend(),
                const SizedBox(height: 12),
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: () => _ajouterTable(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf0eded),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFbecab9).withOpacity(0.3),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child:
                                      Container(color: const Color(0xFFf0eded)),
                                ),
                                ...tables.map((table) {
                                  return Positioned(
                                    left: table.posX * constraints.maxWidth -
                                        (table.largeur + 40) / 2,
                                    top: table.posY * constraints.maxHeight -
                                        (table.hauteur + 40) / 2,
                                    child: DraggableTableWidget(
                                      table: table,
                                      containerWidth: constraints.maxWidth,
                                      containerHeight: constraints.maxHeight,
                                      onLocalUpdate: _updateTableLocally,
                                      onSave: _saveTablePosition,
                                      onAdd: () => _ajouterTable(context),
                                      onEdit: () =>
                                          _modifierTable(context, table),
                                      onDelete: () =>
                                          _supprimerTable(context, table),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
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
  // BARRE DE RECHERCHE + FILTRE
  // ==========================================
  Widget _buildSearchBarWithFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFf6f3f2),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFbecab9).withOpacity(0.3)),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Rechercher une table...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF6f7a6b)),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF6f7a6b), size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFf6f3f2),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFbecab9).withOpacity(0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Color(0xFF6f7a6b), size: 24),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LÉGENDE
  // ==========================================
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Text('Status de table :',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3f4a3c))),
          const SizedBox(width: 12),
          _buildStatusLegend(Colors.green, 'Libre'),
          const SizedBox(width: 8),
          _buildStatusLegend(Colors.orange, 'Occupé'),
        ],
      ),
    );
  }

  Widget _buildStatusLegend(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF3f4a3c))),
      ],
    );
  }

  // ==========================================
  // FILTRE
  // ==========================================
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtrer les tables',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text('Toutes'),
                value: 'TOUS',
                groupValue: _selectedFilter,
                activeColor: const Color(0xFF4caf50),
                onChanged: (value) {
                  setState(() => _selectedFilter = value!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: const Text('Libres'),
                value: 'LIBRE',
                groupValue: _selectedFilter,
                activeColor: const Color(0xFF4caf50),
                onChanged: (value) {
                  setState(() => _selectedFilter = value!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: const Text('Occupées'),
                value: 'OCCUPEE',
                groupValue: _selectedFilter,
                activeColor: const Color(0xFF4caf50),
                onChanged: (value) {
                  setState(() => _selectedFilter = value!);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // ACTIONS CRUD
  // ==========================================

  void _updateTableLocally(TableModel updated) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.updateTableLocal(updated);
  }

  void _saveTablePosition(TableModel updated) async {
    try {
      await Provider.of<AppProvider>(context, listen: false)
          .updateTable(updated);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur sauvegarde : $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _ajouterTable(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddTableSheet(
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _modifierTable(BuildContext context, TableModel table) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditTableSheet(
        table: table,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _supprimerTable(BuildContext context, TableModel table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la table'),
        content: Text('Voulez-vous vraiment supprimer ${table.nom} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              try {
                await Provider.of<AppProvider>(context, listen: false)
                    .deleteTable(table.id);
                if (mounted) {
                  SuccessDialog.show(
                    context,
                    title: 'Supprimée',
                    message: 'La table a été supprimée avec succès.',
                    onDismiss: () {
                      setState(() {});
                    },
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erreur : $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGET TABLE DÉPLAÇABLE (inchangé)
// ============================================================
class DraggableTableWidget extends StatefulWidget {
  final TableModel table;
  final double containerWidth;
  final double containerHeight;
  final void Function(TableModel) onLocalUpdate;
  final void Function(TableModel) onSave;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DraggableTableWidget({
    super.key,
    required this.table,
    required this.containerWidth,
    required this.containerHeight,
    required this.onLocalUpdate,
    required this.onSave,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<DraggableTableWidget> createState() => _DraggableTableWidgetState();
}

class _DraggableTableWidgetState extends State<DraggableTableWidget> {
  double _startX = 0;
  double _startY = 0;
  double _localX = 0;
  double _localY = 0;
  bool _isDragging = false;
  static const double _chairRadius = 7.0;
  static const double _chairSpacing = 6.0;

  @override
  void initState() {
    super.initState();
    _localX = widget.table.posX;
    _localY = widget.table.posY;
  }

  @override
  Widget build(BuildContext context) {
    Color couleur =
        widget.table.isOccupied ? Colors.orange : widget.table.getStatusColor();
    double tableWidth = widget.table.largeur;
    double tableHeight = widget.table.hauteur;
    int capacite = widget.table.capacite;

    double containerWidth = tableWidth + 2 * (_chairRadius + _chairSpacing);
    double containerHeight = tableHeight + 2 * (_chairRadius + _chairSpacing);

    double posX = _isDragging ? _localX : widget.table.posX;
    double posY = _isDragging ? _localY : widget.table.posY;

    return Positioned(
      left: posX * widget.containerWidth - containerWidth / 2,
      top: posY * widget.containerHeight - containerHeight / 2,
      child: GestureDetector(
        onPanStart: (details) {
          _startX = details.globalPosition.dx;
          _startY = details.globalPosition.dy;
          _localX = widget.table.posX;
          _localY = widget.table.posY;
        },
        onPanUpdate: (details) {
          final dx = details.globalPosition.dx - _startX;
          final dy = details.globalPosition.dy - _startY;
          _startX = details.globalPosition.dx;
          _startY = details.globalPosition.dy;

          final dxPercent = dx / widget.containerWidth;
          final dyPercent = dy / widget.containerHeight;
          _localX = (_localX + dxPercent).clamp(0.0, 1.0);
          _localY = (_localY + dyPercent).clamp(0.0, 1.0);
          _isDragging = true;

          final updated = widget.table.copyWith(posX: _localX, posY: _localY);
          widget.onLocalUpdate(updated);
        },
        onPanEnd: (details) {
          if (_isDragging) {
            final updated = widget.table.copyWith(posX: _localX, posY: _localY);
            widget.onSave(updated);
            _isDragging = false;
          }
        },
        onDoubleTap: widget.onEdit,
        onLongPress: _showContextMenu,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: containerWidth,
              height: containerHeight,
              child: Stack(
                children: [
                  Positioned(
                    left: (containerWidth - tableWidth) / 2,
                    top: (containerHeight - tableHeight) / 2,
                    child: _buildTableShape(couleur),
                  ),
                  ..._generateChairs(
                      couleur, capacite, containerWidth, containerHeight),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$capacite places',
              style: GoogleFonts.inter(
                  fontSize: 10, color: const Color(0xFF6f7a6b)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableShape(Color couleur) {
    final String numero = widget.table.nom.replaceAll(RegExp(r'[^0-9]'), '');
    final String displayText = numero.isNotEmpty ? numero : widget.table.nom;

    return Container(
      width: widget.table.largeur,
      height: widget.table.hauteur,
      decoration: BoxDecoration(
        color: couleur,
        shape: _getBoxShape(),
        borderRadius: _getBorderRadius(),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1)
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  BoxShape _getBoxShape() {
    if (widget.table.forme == 'rond') return BoxShape.circle;
    return BoxShape.rectangle;
  }

  BorderRadius? _getBorderRadius() {
    if (widget.table.forme == 'carre') return BorderRadius.circular(8);
    return null;
  }

  List<Widget> _generateChairs(Color couleur, int capacite,
      double containerWidth, double containerHeight) {
    if (capacite < 1) return [];

    double rayon = (widget.table.largeur / 2) + _chairRadius + 2;
    double cx = containerWidth / 2;
    double cy = containerHeight / 2;

    return List.generate(capacite, (index) {
      double angle = (index / capacite) * 2 * math.pi;
      double x = cx + rayon * math.cos(angle) - _chairRadius;
      double y = cy + rayon * math.sin(angle) - _chairRadius;

      return Positioned(
        left: x,
        top: y,
        child: Container(
          width: _chairRadius * 2,
          height: _chairRadius * 2,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: couleur, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  spreadRadius: 0.5)
            ],
          ),
        ),
      );
    });
  }

  void _showContextMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 16),
              const Text(
                'Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onAdd();
                      },
                      icon: const Icon(Icons.add, size: 24),
                      label: const Text(
                        'Ajouter',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006e1c),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onDelete();
                      },
                      icon: const Icon(Icons.delete, size: 24),
                      label: const Text(
                        'Supprimer',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFfe6b00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
