import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/table.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../models/commande.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class AppProvider extends ChangeNotifier {
  // ==========================================
  // DONNÉES
  // ==========================================
  List<TableModel> _tables = [];
  List<MenuItem> _menuItems = [];
  final List<OrderItem> _cart = [];
  int? _selectedTableId;
  bool _isLoading = false;
  String _errorMessage = '';

  List<Map<String, dynamic>> _commandesHistorique = [];

  User? _user;
  Commande? _currentOrder;
  String? _token; // 🔑 Token JWT

  final Map<int, List<OrderItem>> _cartsByTable = {};

  // ==========================================
  // WEBSOCKET
  // ==========================================
  final WebSocketService _wsService = WebSocketService();

  // ==========================================
  // NOTIFICATEUR
  // ==========================================
  final ValueNotifier<int> _tableChangeNotifier = ValueNotifier<int>(0);
  ValueNotifier<int> get tableChangeNotifier => _tableChangeNotifier;

  void _notifyTableChanged() {
    _tableChangeNotifier.value++;
  }

  // ==========================================
  // NOTIFICATION DE CHANGEMENT DE STATUT
  // ==========================================
  Map<String, dynamic>? _lastTableStatusChange;
  DateTime? _lastTableStatusChangeTime;

  Map<String, dynamic>? get lastTableStatusChange => _lastTableStatusChange;

  void consumeLastTableStatusChange() {
    _lastTableStatusChange = null;
    _lastTableStatusChangeTime = null;
  }

  // ==========================================
  // GETTERS
  // ==========================================
  List<TableModel> get tables => _tables;
  List<MenuItem> get menuItems => _menuItems;
  List<OrderItem> get cart => _cart;
  int? get selectedTableId => _selectedTableId;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get commandesHistorique => _commandesHistorique;
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  Commande? get currentOrder => _currentOrder;
  String? get token => _token;

  double get total {
    double sum = 0;
    for (var item in _cart) {
      sum += item.sousTotal;
    }
    return sum;
  }

  int get cartCount {
    int count = 0;
    for (var item in _cart) {
      count += item.quantite;
    }
    return count;
  }

  bool get isCartEmpty => _cart.isEmpty;
  String get peakHour => _dashboardStats['peakHour'] ?? '--:--';
  Map<String, dynamic> get topSelling =>
      _dashboardStats['topSelling'] ?? {'nom': 'Aucun', 'quantite': 0};
  List<dynamic> get outOfStock => _dashboardStats['outOfStock'] ?? [];

  // ==========================================
  // DASHBOARD STATS
  // ==========================================
  Map<String, dynamic> _dashboardStats = {};
  Map<String, dynamic> get dashboardStats => _dashboardStats;

  // ==========================================
  // PERSISTANCE DE LA SESSION
  // ==========================================

  /// Sauvegarde le token et l'utilisateur dans SharedPreferences
  Future<void> _saveAuthData(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  /// Charge les données de session depuis SharedPreferences
  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (token != null && userJson != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(userJson);
        _user = User.fromJson(map);
        _token = token;
        notifyListeners();
        print('✅ Session restaurée pour ${_user?.nom}');
      } catch (e) {
        print('❌ Erreur chargement session : $e');
        await _clearAuthData();
      }
    }
  }

  /// Supprime les données de session
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // ==========================================
  // INITIALISATION
  // ==========================================
  Future<void> loadInitialData() async {
    await loadTables();
    await loadMenu();
    await _loadAuthData(); // ✅ Restaure la session si elle existe
    _loadMockHistory();
  }

  // ==========================================
  // DASHBOARD - Charger les statistiques
  // ==========================================
  Future<void> loadDashboardStats() async {
    try {
      _dashboardStats = await ApiService.getDashboardStats();
      notifyListeners();
      print('📊 Dashboard stats chargées');
    } catch (e) {
      print('❌ loadDashboardStats: $e');
      _dashboardStats = {};
    }
  }

  // ==========================================
  // WEBSOCKET - INITIALISATION
  // ==========================================
  void initWebSocket() {
    final apiUrl = dotenv.env['API_URL'];
    if (apiUrl == null) {
      throw Exception('API_URL non définie dans le fichier .env');
    }
    final wsUrl = apiUrl.replaceFirst('/api', '');
    _wsService.connect(wsUrl);

    _wsService.on('connect', (_) {
      print('✅ WebSocket connecté');
    });

    _wsService.on('disconnect', (_) {
      print('🔴 WebSocket déconnecté');
    });

    _wsService.on('tableStatusChanged', (data) {
      print('📡 Table mise à jour en temps réel : $data');
      final tableId = data['tableId'];
      final newStatus = data['status'];
      final tableData = data['table'];

      final index = _tables.indexWhere((t) => t.id == tableId);
      if (index != -1) {
        if (tableData != null) {
          _tables[index] = TableModel.fromJson(tableData);
        } else {
          _tables[index] = _tables[index].copyWith(status: newStatus);
        }

        _lastTableStatusChange = {
          'tableName': tableData?['nom'] ?? _tables[index].nom,
          'status': newStatus,
        };
        _lastTableStatusChangeTime = DateTime.now();

        notifyListeners();
        _notifyTableChanged();
        print('🔄 Table $tableId mise à jour : $newStatus');
      }
    });

    _wsService.on('error', (data) {
      print('❌ Erreur WebSocket : $data');
    });
  }

  void disposeWebSocket() {
    _wsService.disconnect();
  }

  // ==========================================
  // MISE À JOUR LOCALE DU STATUT DE TABLE
  // ==========================================
  void _updateTableStatusLocally(int tableId, String newStatus) {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index != -1) {
      _tables[index] = _tables[index].copyWith(status: newStatus);
      notifyListeners();
      _notifyTableChanged();
      print('🔄 Statut table $tableId mis à jour localement : $newStatus');
    }
  }

  // ==========================================
  // SAUVEGARDE DU PANIER
  // ==========================================
  Future<void> _saveCartToDatabase() async {
    if (_selectedTableId == null) return;

    try {
      if (_cart.isEmpty) {
        await ApiService.deleteCurrentOrderForTable(_selectedTableId!);
        _updateTableStatusLocally(_selectedTableId!, 'LIBRE');
        _currentOrder = null;
        print('🗑️ Commande supprimée, table libérée localement');
      } else {
        await ApiService.saveCart(_selectedTableId!, _cart);
        _updateTableStatusLocally(_selectedTableId!, 'OCCUPE');
        print('💾 Panier sauvegardé, table marquée OCCUPE localement');
      }
    } catch (e) {
      print('⚠️ Erreur sauvegarde/suppression panier : $e');
    }
  }

  // ==========================================
  // TABLES - CRUD
  // ==========================================
  Future<void> loadTables() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final tables = await ApiService.getTables();
      _tables = tables;
      print('🪑 Tables chargées : ${_tables.length}');
      _notifyTableChanged();
    } catch (e) {
      _errorMessage = 'Erreur chargement tables : $e';
      _tables = [];
      print('❌ loadTables : $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTable(TableModel table) async {
    try {
      final newTable = await ApiService.createTable(table);
      _tables.add(newTable);
      notifyListeners();
      _notifyTableChanged();
      print('✅ Table créée : ${newTable.nom}');
    } catch (e) {
      _errorMessage = 'Erreur création table : $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTable(TableModel table) async {
    try {
      final updated = await ApiService.updateTable(table);
      final index = _tables.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _tables[index] = updated;
        notifyListeners();
        _notifyTableChanged();
        print('✅ Table mise à jour : ${updated.nom}');
      }
    } catch (e) {
      _errorMessage = 'Erreur mise à jour table : $e';
      notifyListeners();
      rethrow;
    }
  }

  void updateTableLocal(TableModel updated) {
    final index = _tables.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _tables[index] = updated;
      notifyListeners();
      _notifyTableChanged();
    }
  }

  Future<void> deleteTable(int id) async {
    try {
      await ApiService.deleteTable(id);
      _tables.removeWhere((t) => t.id == id);
      notifyListeners();
      _notifyTableChanged();
      print('✅ Table supprimée (id: $id)');
    } catch (e) {
      _errorMessage = 'Erreur suppression table : $e';
      notifyListeners();
      rethrow;
    }
  }

  void selectTable(int tableId) {
    _selectedTableId = tableId;
    notifyListeners();
  }

  // ==========================================
  // MENU
  // ==========================================
  Future<void> loadMenu() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final items = await ApiService.getMenu();
      _menuItems = items;
      print('📦 Menu chargé : ${_menuItems.length} articles');
    } catch (e) {
      _errorMessage = 'Erreur chargement menu : $e';
      _menuItems = [];
      print('❌ loadMenu : $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // PANIER
  // ==========================================
  void addToCart(MenuItem item) {
    if (_selectedTableId == null) {
      throw Exception('Veuillez d\'abord sélectionner une table');
    }

    final existingIndex = _cart.indexWhere(
      (cartItem) => cartItem.menuItem.id == item.id,
    );

    if (existingIndex != -1) {
      _cart[existingIndex].quantite++;
    } else {
      _cart.add(OrderItem(menuItem: item));
    }

    _saveCartForCurrentTable();
    _saveCartToDatabase();
    notifyListeners();
  }

  void removeFromCart(int menuItemId) {
    final existingIndex = _cart.indexWhere(
      (item) => item.menuItem.id == menuItemId,
    );

    if (existingIndex != -1) {
      if (_cart[existingIndex].quantite > 1) {
        _cart[existingIndex].quantite--;
      } else {
        _cart.removeAt(existingIndex);
      }
      _saveCartForCurrentTable();
      _saveCartToDatabase();
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _saveCartForCurrentTable();
    _saveCartToDatabase();
    notifyListeners();
  }

  void _saveCartForCurrentTable() {
    if (_selectedTableId != null) {
      _cartsByTable[_selectedTableId!] = List.from(_cart);
    }
  }

  void _loadCartForTable(int tableId) {
    if (_cartsByTable.containsKey(tableId)) {
      _cart.clear();
      _cart.addAll(_cartsByTable[tableId]!);
    } else {
      _cart.clear();
    }
  }

  // ==========================================
  // COMMANDES
  // ==========================================
  Future<void> loadCurrentOrderForTable(int tableId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (_selectedTableId != null && _cart.isNotEmpty) {
        await ApiService.saveCart(_selectedTableId!, _cart);
        print('💾 Panier sauvegardé pour table $_selectedTableId');
      }

      final order = await ApiService.getCurrentOrderForTable(tableId);
      _selectedTableId = tableId;

      if (order != null) {
        _currentOrder = order;
        _cart.clear();
        final items = order.items ?? [];
        for (var item in items) {
          try {
            final menuItem = _menuItems.firstWhere(
              (m) => m.id == item.platId,
            );
            _cart.add(OrderItem(
              menuItem: menuItem,
              quantite: item.quantite,
            ));
          } catch (e) {
            print('⚠️ MenuItem non trouvé pour id ${item.platId}');
          }
        }
        _saveCartForCurrentTable();
        _updateTableStatusLocally(tableId, 'OCCUPE');
        print(
            '📋 Commande chargée pour table $tableId : ${_cart.length} articles');
      } else {
        _currentOrder = null;
        _loadCartForTable(tableId);
        _updateTableStatusLocally(tableId, 'LIBRE');
        print('🆕 Aucune commande en cours pour la table $tableId.');
      }

      await loadTables();
    } catch (e) {
      _errorMessage = 'Erreur chargement commande : $e';
      _currentOrder = null;
      _loadCartForTable(tableId);
      print('❌ loadCurrentOrderForTable : $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitOrder() async {
    if (_cart.isEmpty) {
      throw Exception('Le panier est vide');
    }
    if (_selectedTableId == null) {
      throw Exception('Veuillez sélectionner une table');
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final itemsData = _cart
          .map((item) => {
                'menu_item_id': item.menuItem.id,
                'quantite': item.quantite,
                'prix_unitaire': item.menuItem.prix,
              })
          .toList();

      final orderData = {
        'table_id': _selectedTableId,
        'items': itemsData,
      };

      final result = await ApiService.submitOrder(orderData);

      final commandeId = result['commandeId'];
      final numeroFacture = result['numeroFacture'];
      final total = result['total'];

      _cart.clear();
      _currentOrder = null;
      _cartsByTable.remove(_selectedTableId);
      _selectedTableId = null;

      _commandesHistorique.insert(0, {
        'id': commandeId,
        'numero_facture': numeroFacture,
        'total': total,
        'date_ouverture': DateTime.now().toIso8601String(),
        'date_cloture': DateTime.now().toIso8601String(),
      });

      await loadMenu();
      await loadTables();

      notifyListeners();
      print('✅ Commande validée et payée, table libérée');

      return {
        'commandeId': commandeId,
        'numeroFacture': numeroFacture,
        'total': total,
      };
    } catch (e) {
      _errorMessage = 'Erreur lors de la validation : $e';
      print('❌ submitOrder : $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markOrderAsPaid(int orderId) async {
    try {
      await ApiService.markOrderAsPaid(orderId);
      if (_currentOrder?.id == orderId) {
        _currentOrder = null;
        _cart.clear();
        notifyListeners();
      }
      print('✅ Commande #$orderId marquée payée');
    } catch (e) {
      print('❌ markOrderAsPaid : $e');
    }
  }

  void _loadMockHistory() {
    _commandesHistorique = [];
  }

  // ==========================================
  // 🔐 AUTHENTIFICATION
  // ==========================================

  Future<bool> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);
      _user = User.fromJson(response['user']);
      _token = response['token'];
      await _saveAuthData(_user!, _token!);
      _errorMessage = '';
      notifyListeners();
      print('✅ Login réussi : ${_user?.nom}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _user = null;
      _token = null;
      notifyListeners();
      print('❌ Login échoué : $e');
      return false;
    }
  }

  void logout() {
    _user = null;
    _token = null;
    _clearAuthData();
    _cart.clear();
    _selectedTableId = null;
    _cartsByTable.clear();
    _wsService.disconnect();
    notifyListeners();
    print('🔓 Déconnexion effectuée');
  }

  // ==========================================
  // 👤 UTILISATEUR (Public, sans token)
  // ==========================================

  Future<void> loadUser() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await ApiService.getCurrentUser();
      _user = user;
      print('✅ Utilisateur chargé : ${user.nom}');
    } catch (e) {
      _errorMessage = 'Erreur chargement utilisateur : $e';
      _user = null;
      print('❌ loadUser : $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Ajout du paramètre imageUrl
  Future<User?> updateCurrentUser({
    required String nom,
    required String email,
    String? imageUrl, // ✅ URL Cloudinary
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final data = {'nom': nom, 'email': email};
      if (imageUrl != null && imageUrl.isNotEmpty) {
        data['image_url'] = imageUrl;
      }
      final updatedUser = await ApiService.updateCurrentUser(data);
      _user = updatedUser;
      // Mettre à jour la session persistante
      if (_token != null) {
        await _saveAuthData(_user!, _token!);
      }
      print('✅ Profil mis à jour : ${updatedUser.nom}');
      return updatedUser;
    } catch (e) {
      _errorMessage = 'Erreur mise à jour profil : $e';
      print('❌ updateCurrentUser : $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ⚠️ Cette méthode est conservée pour compatibilité, mais vous pouvez la supprimer
  // si vous utilisez désormais updateCurrentUser avec imageUrl.
  Future<User?> updateCurrentUserWithImage({
    required String nom,
    required String email,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final data = {'nom': nom, 'email': email};
      final updatedUser = await ApiService.updateCurrentUserWithImage(
        data: data,
        imageBytes: imageBytes,
        fileName: fileName,
      );
      _user = updatedUser;
      if (_token != null) {
        await _saveAuthData(_user!, _token!);
      }
      print('✅ Profil mis à jour avec image : ${updatedUser.nom}');
      return updatedUser;
    } catch (e) {
      _errorMessage = 'Erreur mise à jour profil avec image : $e';
      print('❌ updateCurrentUserWithImage : $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateLocalUser({String? nom, String? email, String? imageUrl}) {
    _user = _user?.copyWith(
      nom: nom ?? _user?.nom,
      email: email ?? _user?.email,
      imageUrl: imageUrl ?? _user?.imageUrl,
    );
    if (_token != null && _user != null) {
      _saveAuthData(_user!, _token!);
    }
    notifyListeners();
    print('✅ Utilisateur mis à jour localement');
  }

  @override
  void dispose() {
    _tableChangeNotifier.dispose();
    _wsService.disconnect();
    super.dispose();
  }
}
