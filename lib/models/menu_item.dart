import 'package:flutter/material.dart';

class MenuItem {
  final int id;
  final String nom;
  final String? description;
  final double prix;
  final String? imageUrl;
  final int quantite;
  final String categorie;

  MenuItem({
    required this.id,
    required this.nom,
    this.description,
    required this.prix,
    this.imageUrl,
    this.quantite = 0,
    required this.categorie,
  });

  // ==========================================
  // 🔄 JSON → OBJET (avec gestion robuste du prix)
  // ==========================================
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    double parsePrix(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MenuItem(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      description: json['description'],
      prix: parsePrix(json['prix']),
      imageUrl: json['image_url'],
      quantite: json['quantite'] ?? 0,
      categorie: json['categorie'] ?? 'PLAT',
    );
  }

  // ==========================================
  // 🔄 OBJET → JSON
  // ==========================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'prix': prix,
      'image_url': imageUrl,
      'quantite': quantite,
      'categorie': categorie,
    };
  }

  // ==========================================
  // 🎨 MÉTHODES UTILITAIRES POUR L'UI
  // ==========================================
  IconData getCategoryIcon() {
    switch (categorie) {
      case 'ENTREE':
        return Icons.food_bank;
      case 'PLAT':
        return Icons.restaurant;
      case 'DESSERT':
        return Icons.cake;
      case 'BOISSON':
        return Icons.local_drink;
      default:
        return Icons.food_bank;
    }
  }

  Color getCategoryColor() {
    switch (categorie) {
      case 'ENTREE':
        return Colors.blue;
      case 'PLAT':
        return Colors.orange;
      case 'DESSERT':
        return Colors.pink;
      case 'BOISSON':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}
