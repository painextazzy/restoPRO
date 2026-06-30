import 'package:flutter/material.dart';

class TableModel {
  final int id;
  String nom;
  int capacite;
  String status; // 'LIBRE' ou 'OCCUPEE'
  double posX;
  double posY;
  double largeur;
  double hauteur;
  String forme; // 'rond' ou 'carre'

  TableModel({
    required this.id,
    required this.nom,
    this.capacite = 4,
    this.status = 'LIBRE',
    this.posX = 0.5,
    this.posY = 0.5,
    this.largeur = 70,
    this.hauteur = 70,
    this.forme = 'rond',
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      nom: json['nom'] ?? 'Table ${json['id']}',
      capacite: json['capacite'] ?? 4,
      status: json['status'] ?? 'LIBRE',
      posX: (json['pos_x'] ?? 0.5).toDouble(),
      posY: (json['pos_y'] ?? 0.5).toDouble(),
      largeur: (json['largeur'] ?? 70).toDouble(),
      hauteur: (json['hauteur'] ?? 70).toDouble(),
      forme: json['forme'] ?? 'rond',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'capacite': capacite,
      'status': status,
      'pos_x': posX,
      'pos_y': posY,
      'largeur': largeur,
      'hauteur': hauteur,
      'forme': forme,
    };
  }

  TableModel copyWith({
    int? id,
    String? nom,
    int? capacite,
    String? status,
    double? posX,
    double? posY,
    double? largeur,
    double? hauteur,
    String? forme,
  }) {
    return TableModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      capacite: capacite ?? this.capacite,
      status: status ?? this.status,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      largeur: largeur ?? this.largeur,
      hauteur: hauteur ?? this.hauteur,
      forme: forme ?? this.forme,
    );
  }

  // ==========================================
  // 🎨 MÉTHODES UTILITAIRES
  // ==========================================
  bool get isOccupied => status == 'OCCUPE';
  bool get isAvailable => status == 'LIBRE';

  Color getStatusColor() {
    if (isOccupied) return Colors.orange;
    return Colors.green;
  }

  String getStatusLabel() {
    if (isOccupied) return 'Occupée';
    return 'Libre';
  }

  // ✅ AJOUT DE L'ICÔNE
  IconData getStatusIcon() {
    if (isOccupied) return Icons.people;
    return Icons.check_circle;
  }
}
