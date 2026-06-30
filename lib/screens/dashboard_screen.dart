import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadDashboardStats();
    });
  }

  // ==========================================
  // CONVERSION SÉCURISÉE
  // ==========================================
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(' ', '').replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(' ', '').replaceAll(',', '.');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final stats = appProvider.dashboardStats;

    final totalVentes = _toDouble(stats['totalVentes']);
    final nombreCommandes = _toInt(stats['nombreCommandes']);
    final commandesEncours = _toInt(stats['commandesEncours']);
    final tablesOccupees = _toInt(stats['tablesOccupees']);
    final tablesDisponibles = _toInt(stats['tablesDisponibles']);
    final tempsMoyen = _toInt(stats['tempsMoyen']);
    final dernieresCommandes = (stats['dernieresCommandes'] as List? ?? []);

    final peakHour = appProvider.peakHour;
    final topSelling = appProvider.topSelling;
    final outOfStock = appProvider.outOfStock;

    final formatter = NumberFormat('#,###', 'fr_FR');
    final caFormatted = formatter.format(totalVentes);

    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      body: RefreshIndicator(
        onRefresh: () async {
          await appProvider.loadDashboardStats();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Vue d\'ensemble de votre activité',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6f7a6b),
                ),
              ),
              const SizedBox(height: 24),

              // Ligne 1 : CA + Commandes
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'CA Total',
                      value: '$caFormatted Ar',
                      icon: Icons.attach_money,
                      color: const Color(0xFF006e1c),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Commandes',
                      value: '$nombreCommandes',
                      icon: Icons.receipt_long,
                      color: const Color(0xFF4caf50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ligne 2 : En cours + Tables
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'En cours',
                      value: '$commandesEncours',
                      icon: Icons.timer,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Occupées',
                      value: '$tablesOccupees',
                      icon: Icons.table_restaurant,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Libres',
                      value: '$tablesDisponibles',
                      icon: Icons.table_restaurant_outlined,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Temps moyen
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF006e1c)),
                    const SizedBox(width: 8),
                    Text(
                      'Temps moyen de service :',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6f7a6b),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$tempsMoyen min',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1b1c1c),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Heure de pointe
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(
                      'Heure de pointe :',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6f7a6b),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      peakHour,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1b1c1c),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Plat le plus vendu
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plat le plus vendu',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6f7a6b),
                            ),
                          ),
                          Text(
                            '${topSelling['nom']} (${topSelling['quantite']} vendus)',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1b1c1c),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // ⚠️ STOCKS ÉPUISÉS (CARTE RECTANGLE TOUJOURS VISIBLE)
              // ==========================================
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Stocks épuisés',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            outOfStock.isNotEmpty ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (outOfStock.isNotEmpty)
                      ...outOfStock.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '• ${item['nom']}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF1b1c1c),
                              ),
                            ),
                          ))
                    else
                      Text(
                        '✅ Aucun stock épuisé',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF4caf50),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Graphique
              _buildSalesChart(dernieresCommandes),
              const SizedBox(height: 24),

              // Dernières commandes
              _buildRecentOrders(dernieresCommandes),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CARTE DE STATISTIQUES
  // ==========================================
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1b1c1c),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF6f7a6b),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GRAPHIQUE AVEC fl_chart
  // ==========================================
  Widget _buildSalesChart(List dernieresCommandes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution des ventes (5 dernières)',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1b1c1c),
            ),
          ),
          const SizedBox(height: 16),
          if (dernieresCommandes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Icon(Icons.show_chart, size: 50, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune vente récente',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue(dernieresCommandes) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dernieresCommandes.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '#${index + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF6f7a6b),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value > 0) {
                            return Text(
                              '${(value / 1000).toStringAsFixed(0)}k',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF6f7a6b),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 35,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: _getMaxValue(dernieresCommandes) / 4,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Color(0xFFf0eded),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: dernieresCommandes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cmd = entry.value;
                    final total = _toDouble(cmd['total']);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: total,
                          color: const Color(0xFF4caf50),
                          width: 24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _getMaxValue(List dernieresCommandes) {
    double max = 0;
    for (var cmd in dernieresCommandes) {
      final total = _toDouble(cmd['total']);
      if (total > max) max = total;
    }
    return max > 0 ? max : 1000;
  }

  // ==========================================
  // DERNIÈRES COMMANDES
  // ==========================================
  Widget _buildRecentOrders(List dernieresCommandes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dernières commandes',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1b1c1c),
            ),
          ),
          const SizedBox(height: 12),
          if (dernieresCommandes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune commande',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dernieresCommandes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cmd = dernieresCommandes[index];
                final total = _toDouble(cmd['total']);
                String dateStr = '';
                if (cmd['date_ouverture'] != null) {
                  try {
                    dateStr = DateTime.parse(cmd['date_ouverture'])
                        .toLocal()
                        .toString()
                        .substring(0, 16);
                  } catch (_) {}
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4caf50).withOpacity(0.2),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006e1c),
                      ),
                    ),
                  ),
                  title: Text(
                    cmd['numero_facture'] ?? 'Commande',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1b1c1c),
                    ),
                  ),
                  subtitle: Text(
                    'Table ${cmd['table_id']} · $dateStr',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6f7a6b),
                    ),
                  ),
                  trailing: Text(
                    '${total.toStringAsFixed(0)} Ar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF006e1c),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
