class InvoiceData {
  final String numeroFacture;
  final String date;
  final String adresse;
  final List<InvoiceItem> items;
  final double total;
  final String barcode;

  InvoiceData({
    required this.numeroFacture,
    required this.date,
    required this.adresse,
    required this.items,
    required this.total,
    required this.barcode,
  });

  factory InvoiceData.fromJson(Map<String, dynamic> json) {
    return InvoiceData(
      numeroFacture: json['numeroFacture'] ?? 'N/A',
      date: json['date'] ?? DateTime.now().toIso8601String().split('T').first,
      adresse: json['adresse'] ?? '',
      items: (json['items'] as List?)
              ?.map((i) => InvoiceItem.fromJson(i))
              .toList() ??
          [],
      total: (json['total'] is num)
          ? (json['total'] as num).toDouble()
          : double.tryParse(json['total'].toString()) ?? 0.0,
      barcode: json['barcode'] ?? '',
    );
  }
}

class InvoiceItem {
  final String nom;
  final int quantite;
  final double prixUnitaire;
  final double totalLigne;

  InvoiceItem({
    required this.nom,
    required this.quantite,
    required this.prixUnitaire,
    required this.totalLigne,
  });

  String get formattedPrix => prixUnitaire.toStringAsFixed(2);
  String get formattedTotal => totalLigne.toStringAsFixed(2);

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      nom: json['nom'] ?? '',
      quantite: (json['quantite'] as num?)?.toInt() ?? 0,
      prixUnitaire: (json['prix_unitaire'] is num)
          ? (json['prix_unitaire'] as num).toDouble()
          : double.tryParse(json['prix_unitaire'].toString()) ?? 0.0,
      totalLigne: (json['total_ligne'] is num)
          ? (json['total_ligne'] as num).toDouble()
          : double.tryParse(json['total_ligne'].toString()) ?? 0.0,
    );
  }
}
