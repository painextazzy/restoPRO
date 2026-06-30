import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/menu_item.dart';
import '../models/table.dart';
import '../models/user.dart';
import '../models/commande.dart';
import '../models/order.dart'; // ✅ Pour OrderItem

class ApiService {
  static String get baseUrl {
    return dotenv.env['API_URL'] ?? 'http://localhost:3000/api';
  }

  // ==========================================
  // TABLES - CRUD
  // ==========================================

  static Future<List<TableModel>> getTables() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tables'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => TableModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur chargement tables');
    }
  }

  static Future<TableModel> getTable(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tables/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return TableModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur chargement table');
    }
  }

  static Future<TableModel> createTable(TableModel table) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tables'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(table.toJson()),
    );
    if (response.statusCode == 201) {
      return TableModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur création table');
    }
  }

  static Future<TableModel> updateTable(TableModel table) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tables/${table.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(table.toJson()),
    );
    if (response.statusCode == 200) {
      return TableModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur mise à jour table');
    }
  }

  static Future<void> deleteTable(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tables/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur suppression table');
    }
  }

  // ==========================================
  // TABLES - GESTION DES STATUTS
  // ==========================================

  static Future<void> markTableAsOccupied(int tableId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tables/$tableId/occuper'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ markTableAsOccupied : $e');
      rethrow;
    }
  }

  static Future<void> markTableAsFree(int tableId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tables/$tableId/liberer'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ markTableAsFree : $e');
      rethrow;
    }
  }

  // ==========================================
  // MENU - CRUD
  // ==========================================

  static Future<List<MenuItem>> getMenu() async {
    final response = await http.get(
      Uri.parse('$baseUrl/menu'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => MenuItem.fromJson(json)).toList();
    } else {
      throw Exception('Erreur chargement menu');
    }
  }

  static Future<MenuItem> getMenuItem(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/menu/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return MenuItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur chargement article');
    }
  }

  static Future<MenuItem> createMenuItem(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/menu'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return MenuItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur création');
    }
  }

  static Future<MenuItem> createMenuItemWithImageBytes({
    required String nom,
    required String description,
    required double prix,
    required int quantite,
    required String categorie,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/menu'),
    );

    request.fields['nom'] = nom;
    request.fields['description'] = description;
    request.fields['prix'] = prix.toString();
    request.fields['quantite'] = quantite.toString();
    request.fields['categorie'] = categorie;

    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: fileName,
    );
    request.files.add(multipartFile);

    final response = await request.send();
    if (response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      return MenuItem.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception('Erreur création avec image');
    }
  }

  static Future<MenuItem> updateMenuItemWithImageBytes({
    required int id,
    required String nom,
    required String description,
    required double prix,
    required int quantite,
    required String categorie,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/menu/$id'),
    );

    request.fields['nom'] = nom;
    request.fields['description'] = description;
    request.fields['prix'] = prix.toString();
    request.fields['quantite'] = quantite.toString();
    request.fields['categorie'] = categorie;

    if (imageBytes != null && fileName != null) {
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return MenuItem.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception('Erreur mise à jour avec image');
    }
  }

  static Future<MenuItem> updateMenuItem(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/menu/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return MenuItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur mise à jour');
    }
  }

  static Future<void> deleteMenuItem(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/menu/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur suppression');
    }
  }

  // ==========================================
  // COMMANDES
  // ==========================================

  static Future<Commande?> getCurrentOrderForTable(int tableId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/commandes/table/$tableId/encours'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Commande.fromJson(json);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ getCurrentOrderForTable : $e');
      return null;
    }
  }

  // ✅ Version corrigée : extrait le message d'erreur détaillé
  static Future<Map<String, dynamic>> submitOrder(
      Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/commandes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        // Extraire le message d'erreur du corps
        String errorMessage = 'Erreur ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson['message'] != null) {
            errorMessage = errorJson['message'];
          } else if (errorJson['error'] != null &&
              errorJson['error'] is String) {
            errorMessage = errorJson['error'];
          } else if (errorJson['error'] is Map &&
              errorJson['error']['details'] != null) {
            final details = errorJson['error']['details'];
            errorMessage =
                'Stock insuffisant pour l\'article "${details['itemName']}". Disponible: ${details['disponible']}, demandé: ${details['demande']}';
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ submitOrder : $e');
      rethrow;
    }
  }

  static Future<void> markOrderAsPaid(int orderId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/commandes/$orderId/payer'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ markOrderAsPaid : $e');
      rethrow;
    }
  }

  static Future<Commande> getOrderWithItems(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/commandes/$orderId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return Commande.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur chargement commande');
    }
  }

  // ==========================================
  // SAUVEGARDE DU PANIER (sans payer)
  // ==========================================
  static Future<void> saveCart(int tableId, List<OrderItem> cart) async {
    try {
      final itemsData = cart
          .map((item) => {
                'menu_item_id': item.menuItem.id,
                'quantite': item.quantite,
                'prix_unitaire': item.menuItem.prix,
              })
          .toList();

      final response = await http.post(
        Uri.parse('$baseUrl/commandes/sauvegarder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'table_id': tableId,
          'items': itemsData,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ saveCart : $e');
      rethrow;
    }
  }

  // ==========================================
  // 👤 UTILISATEUR (PUBLIC, sans token)
  // ==========================================

  static Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur chargement utilisateur');
    }
  }

  static Future<User> updateCurrentUser(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur mise à jour utilisateur');
    }
  }

  static Future<User> updateCurrentUserWithImage({
    required Map<String, dynamic> data,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/users/me'),
    );

    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: fileName,
    );
    request.files.add(multipartFile);

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return User.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception('Erreur mise à jour utilisateur avec image');
    }
  }

  static Future<void> deleteCurrentOrderForTable(int tableId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/commandes/table/$tableId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200 && response.statusCode != 404) {
      throw Exception('Erreur suppression commande');
    }
  }

  // services/api_service.dart
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/commandes/dashboard/stats'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur chargement dashboard');
    }
  }

  // services/api_service.dart
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur de connexion');
    }
  }
}
