import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../models/order.dart';
import '../models/table.dart';
import 'invoice_screen.dart';
import '../models/invoice_data.dart';
import '../services/api_service.dart'; // ✅ Ajout
import '../utils/type_converter.dart'; // ✅ Ajout

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final cart = appProvider.cart;
    final total = appProvider.total;
    final tables = appProvider.tables;

    // ==========================================
    // 1️⃣ AUCUNE TABLE SÉLECTIONNÉE
    // ==========================================
    if (appProvider.selectedTableId == null) {
      return _buildNoTableSelected(tables, appProvider);
    }

    // ==========================================
    // 2️⃣ PANIER VIDE
    // ==========================================
    if (cart.isEmpty) {
      return _buildEmptyCart(appProvider, tables);
    }

    // ==========================================
    // 3️⃣ PANIER AVEC CONTENU
    // ==========================================
    return _buildCartWithItems(appProvider, tables, cart, total);
  }

  // ------------------------------------------------------------
  // WIDGET : Pas de table sélectionnée
  // ------------------------------------------------------------
  Widget _buildNoTableSelected(List<TableModel> tables, AppProvider provider) {
    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4caf50).withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.table_restaurant,
                  size: 60,
                  color: Color(0xFF4caf50),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sélectionnez une table',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1b1c1c),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez une table pour commencer\nà prendre les commandes',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6f7a6b),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (tables.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: provider.selectedTableId,
                      isExpanded: true,
                      hint: Text(
                        'Choisir une table',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFF6f7a6b),
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_drop_down_circle,
                        color: Color(0xFF4caf50),
                        size: 32,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1b1c1c),
                      ),
                      items: tables.map((table) {
                        final isSelected = provider.selectedTableId == table.id;
                        return DropdownMenuItem<int>(
                          value: table.id,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: table.isOccupied
                                      ? Colors.orange
                                      : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  table.nom,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF4caf50)
                                        : const Color(0xFF1b1c1c),
                                  ),
                                ),
                              ),
                              if (table.isOccupied)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Occupée',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4caf50)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF4caf50)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: const Color(0xFF4caf50),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          provider.loadCurrentOrderForTable(newValue);
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                      },
                    ),
                  ),
                )
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 16),
              if (tables.isNotEmpty)
                TextButton(
                  onPressed: () {
                    provider.loadTables();
                  },
                  child: Text(
                    'Rafraîchir la liste',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF4caf50),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // WIDGET : Panier vide
  // ------------------------------------------------------------
  Widget _buildEmptyCart(AppProvider provider, List<TableModel> tables) {
    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      body: Column(
        children: [
          _buildHeader(provider, tables),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Panier vide',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1b1c1c),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez des plats depuis le menu',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6f7a6b),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Ajoutez des plats depuis l\'onglet Menu'),
                            backgroundColor: Colors.blue,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Voir le menu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4caf50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // WIDGET : Panier avec contenu
  // ------------------------------------------------------------
  Widget _buildCartWithItems(
    AppProvider provider,
    List<TableModel> tables,
    List<OrderItem> cart,
    double total,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      body: Column(
        children: [
          _buildHeader(provider, tables),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFFd1e8d5), const Color(0xFFfcf9f8)],
                  stops: const [0.0, 0.4],
                ),
              ),
              child: Column(
                children: [
                  // Compteur + bouton vider
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cart.length} article${cart.length > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF6f7a6b),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            provider.clearCart();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Panier vidé et table libérée'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Vider',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Liste des articles
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final orderItem = cart[index];
                        return Dismissible(
                          key: ValueKey(orderItem.menuItem.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          onDismissed: (direction) {
                            provider.removeFromCart(orderItem.menuItem.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${orderItem.menuItem.nom} retiré du panier',
                                ),
                                backgroundColor: Colors.red.shade300,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: _buildCartItemCard(orderItem, provider),
                        );
                      },
                    ),
                  ),
                  // Résumé + validation
                  _buildSummaryAndCheckout(context, provider, total),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER AVEC DROPDOWN DE TABLE
  // ------------------------------------------------------------
  Widget _buildHeader(AppProvider provider, List<TableModel> tables) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFf0eded),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4caf50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.table_restaurant,
              color: Color(0xFF4caf50),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFf6f3f2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: provider.selectedTableId,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF4caf50),
                    size: 28,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1b1c1c),
                  ),
                  items: tables.map((table) {
                    final isSelected = provider.selectedTableId == table.id;
                    return DropdownMenuItem<int>(
                      value: table.id,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: table.isOccupied
                                  ? Colors.orange
                                  : isSelected
                                      ? const Color(0xFF4caf50)
                                      : Colors.green,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              table.nom,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF4caf50)
                                    : table.isOccupied
                                        ? Colors.orange.shade700
                                        : const Color(0xFF1b1c1c),
                              ),
                            ),
                          ),
                          if (table.isOccupied)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                'Occupée',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4caf50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      const Color(0xFF4caf50).withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                'Active',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4caf50),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      provider.loadCurrentOrderForTable(newValue);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CARTE D'UN ARTICLE AVEC INDICATEUR DE STOCK
  // ------------------------------------------------------------
  Widget _buildCartItemCard(OrderItem orderItem, AppProvider provider) {
    final item = orderItem.menuItem;
    final imageUrl =
        item.imageUrl != null ? 'http://localhost:3000${item.imageUrl}' : null;

    final bool isStockEmpty = item.quantite <= 0;
    final bool isAtMaxStock =
        orderItem.quantite >= item.quantite && item.quantite > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFfdf2e9),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.fastfood,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                : Icon(Icons.fastfood, size: 40, color: Colors.grey[400]),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nom,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1b1c1c),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Stock
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: Color(0xFF6f7a6b),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: ${item.quantite}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color:
                            isStockEmpty ? Colors.red : const Color(0xFF6f7a6b),
                        fontWeight:
                            isStockEmpty ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                // ⚠️ Rupture de stock
                if (isStockEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '⚠️ Rupture de stock',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                // Prix
                Text(
                  '${item.prix.toStringAsFixed(0)} Ar',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006e1c),
                  ),
                ),
              ],
            ),
          ),
          // Contrôle de quantité
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFf6f3f2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => provider.removeFromCart(item.id),
                  color: const Color(0xFF6f7a6b),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${orderItem.quantite}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1b1c1c),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: (isStockEmpty || isAtMaxStock)
                      ? null
                      : () => provider.addToCart(item),
                  color: (isStockEmpty || isAtMaxStock)
                      ? Colors.grey
                      : const Color(0xFF006e1c),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // RÉSUMÉ + BOUTON DE VALIDATION AVEC FACTURE (CORRIGÉ)
  // ------------------------------------------------------------
  Widget _buildSummaryAndCheckout(
    BuildContext context,
    AppProvider provider,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1b1c1c),
                ),
              ),
              Row(
                children: [
                  Text(
                    total.toStringAsFixed(0),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF006e1c),
                    ),
                  ),
                  Text(
                    ' Ar',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6f7a6b),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                '${provider.cart.length} article${provider.cart.length > 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (provider.selectedTableId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez sélectionner une table'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  // 1️⃣ Paiement
                  final result = await provider.submitOrder();
                  final commandeId = result['commandeId'];

                  // 2️⃣ Récupération de la commande avec ses lignes
                  final commande =
                      await ApiService.getOrderWithItems(commandeId);

                  // 3️⃣ Construction des articles de la facture
                  final items = commande.items.map((item) {
                    return InvoiceItem(
                      nom: item.nomPlat ?? 'Article inconnu',
                      quantite: item.quantite,
                      prixUnitaire: item.prixUnitaire,
                      totalLigne: item.totalLigne,
                    );
                  }).toList();

                  // 4️⃣ Conversion sécurisée du total
                  final totalFacture = TypeConverter.toDouble(commande.total);

                  // 5️⃣ Création des données de facture
                  final invoiceData = InvoiceData(
                    numeroFacture: commande.numeroFacture,
                    date: commande.dateOuverture
                        .toIso8601String()
                        .split('T')
                        .first,
                    adresse: '123 Rue de la Gastronomie, Paris',
                    items: items,
                    total: totalFacture,
                    barcode: 'INV-${commande.id}',
                  );

                  // 6️⃣ Navigation vers InvoiceScreen
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            InvoiceScreen(invoiceData: invoiceData),
                      ),
                    );
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Commande validée avec succès !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  String message = e.toString().replaceFirst('Exception: ', '');
                  if (message.contains('Stock insuffisant') ||
                      message.contains('rupture de stock')) {
                    _showStockErrorDialog(context, message);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1b1c1c),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 20),
                  const SizedBox(width: 8),
                  const Text('Valider le paiement'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DIALOGUE D'ERREUR DE STOCK
  // ------------------------------------------------------------
  void _showStockErrorDialog(BuildContext context, String errorMessage) {
    final RegExp regExp =
        RegExp(r'"([^"]+)" \(ID (\d+)\)\. Disponible: (\d+), demandé: (\d+)');
    final match = regExp.firstMatch(errorMessage);

    String itemName = 'Article';
    String disponible = '?';
    String demande = '?';

    if (match != null) {
      itemName = match.group(1) ?? 'Article';
      disponible = match.group(3) ?? '?';
      demande = match.group(4) ?? '?';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Stock insuffisant'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L\'article "$itemName" ne peut pas être commandé.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Disponible',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        disponible,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  Column(
                    children: [
                      const Text('Demandé',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        demande,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez réduire la quantité ou choisir un autre article.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
