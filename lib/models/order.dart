import 'package:flutter/material.dart';
import 'menu_item.dart';

class OrderItem {
  final MenuItem menuItem;
  int quantite;

  OrderItem({required this.menuItem, this.quantite = 1});

  double get sousTotal => menuItem.prix * quantite;
}

class OrderModel extends ChangeNotifier {
  final List<OrderItem> _items = [];
  int? _tableId;
  int _commandeCounter = 0;
  final List<Map<String, dynamic>> _commandesHistorique = [];

  List<OrderItem> get items => _items;
  int? get tableId => _tableId;

  double get total {
    double sum = 0;
    for (var item in _items) {
      sum += item.sousTotal;
    }
    return sum;
  }

  int get itemCount {
    int count = 0;
    for (var item in _items) {
      count += item.quantite;
    }
    return count;
  }

  bool get isEmpty => _items.isEmpty;
  List<Map<String, dynamic>> get commandesHistorique => _commandesHistorique;

  void setTable(int tableId) {
    _tableId = tableId;
    notifyListeners();
  }

  void addItem(MenuItem menuItem) {
    final existingIndex = _items.indexWhere(
      (item) => item.menuItem.id == menuItem.id,
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantite++;
    } else {
      _items.add(OrderItem(menuItem: menuItem));
    }
    notifyListeners();
  }

  void removeItem(int menuItemId) {
    final existingIndex = _items.indexWhere(
      (item) => item.menuItem.id == menuItemId,
    );

    if (existingIndex != -1) {
      if (_items[existingIndex].quantite > 1) {
        _items[existingIndex].quantite--;
      } else {
        _items.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void clearOrder() {
    _items.clear();
    _tableId = null;
    notifyListeners();
  }

  void submitOrder() {
    if (_items.isEmpty || _tableId == null) return;

    _commandeCounter++;
    final now = DateTime.now();
    final commande = {
      'id': _commandeCounter,
      'numero_facture':
          'FACT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${_commandeCounter.toString().padLeft(4, '0')}',
      'table_id': _tableId,
      'date_ouverture': now.toIso8601String(),
      'total': total,
      'items': _items
          .map(
            (item) => {
              'nom': item.menuItem.nom,
              'quantite': item.quantite,
              'prix_unitaire': item.menuItem.prix,
              'total': item.sousTotal,
            },
          )
          .toList(),
    };

    _commandesHistorique.insert(0, commande);
    clearOrder();
    notifyListeners();
  }

  // ❌ SUPPRIMER cette méthode → elle n'est plus utilisée
  // void addMockItems() { ... }
}
