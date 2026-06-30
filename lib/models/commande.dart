import 'package:equatable/equatable.dart';
import 'commande_item.dart';
import '../utils/type_converter.dart';

class Commande extends Equatable {
  final int? id;
  final String numeroFacture;
  final int tableId;
  final DateTime dateOuverture;
  final DateTime? dateCloture;
  final String statut;
  final double total;
  final List<CommandeItem> items;

  const Commande({
    this.id,
    required this.numeroFacture,
    required this.tableId,
    required this.dateOuverture,
    this.dateCloture,
    this.statut = 'en_cours',
    this.total = 0.0,
    this.items = const [],
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: TypeConverter.toInt(json['id']), // ✅ corrigé
      numeroFacture: json['numero_facture'] ?? '',
      tableId: TypeConverter.toInt(json['table_id']), // ✅ corrigé
      dateOuverture: json['date_ouverture'] != null
          ? DateTime.parse(json['date_ouverture'])
          : DateTime.now(),
      dateCloture: json['date_cloture'] != null
          ? DateTime.parse(json['date_cloture'])
          : null,
      statut: json['statut'] ?? 'en_cours',
      total: TypeConverter.toDouble(json['total']),
      items: (json['items'] as List? ?? [])
          .map((item) => CommandeItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_facture': numeroFacture,
      'table_id': tableId,
      'date_ouverture': dateOuverture.toIso8601String(),
      'date_cloture': dateCloture?.toIso8601String(),
      'statut': statut,
      'total': total,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        numeroFacture,
        tableId,
        dateOuverture,
        dateCloture,
        statut,
        total,
        items,
      ];
}
