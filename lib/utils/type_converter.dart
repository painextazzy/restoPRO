class TypeConverter {
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // ✅ Nettoyer : supprimer les espaces, virgules, etc.
      final cleaned = value.replaceAll(' ', '').replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(' ', '').replaceAll(',', '.');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }
}
