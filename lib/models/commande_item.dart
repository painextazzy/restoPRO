import 'package:equatable/equatable.dart';
import '../utils/type_converter.dart';

class CommandeItem extends Equatable {
  final int? id;
  final int commandeId;
  final int platId; // correspond au menu_item_id
  final int quantite;
  final double prixUnitaire;
  final double
      totalLigne; // correspond au champ "total" de la table (alias total_ligne en retour)
  final String? nomPlat; // optionnel, récupéré via la jointure avec menu

  const CommandeItem({
    this.id,
    required this.commandeId,
    required this.platId,
    required this.quantite,
    required this.prixUnitaire,
    required this.totalLigne,
    this.nomPlat,
  });

  factory CommandeItem.fromJson(Map<String, dynamic> json) {
    return CommandeItem(
      id: TypeConverter.toInt(json['id']),
      commandeId: TypeConverter.toInt(json['commande_id']),
      platId: TypeConverter.toInt(
          json['plat_id'] ?? json['menu_item_id']), // fallback
      quantite: TypeConverter.toInt(json['quantite']),
      prixUnitaire: TypeConverter.toDouble(json['prix_unitaire']),
      totalLigne: TypeConverter.toDouble(
          json['total_ligne'] ?? json['total']), // fallback
      nomPlat: json['nom_plat'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commande_id': commandeId,
      'plat_id': platId,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'total': totalLigne,
    };
  }

  @override
  List<Object?> get props => [
        id,
        commandeId,
        platId,
        quantite,
        prixUnitaire,
        totalLigne,
        nomPlat,
      ];
}
