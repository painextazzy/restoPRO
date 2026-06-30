import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'menu_screen.dart';
import 'order_screen.dart';
import 'profile_screen.dart';
import 'tables_screen.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  static final GlobalKey<_HomeScreenState> globalKey =
      GlobalKey<_HomeScreenState>();

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MenuScreen(),
    OrderScreen(),
    TablesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.initWebSocket();
      appProvider.addListener(_onTableStatusChanged);
    });
  }

  @override
  void dispose() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.removeListener(_onTableStatusChanged);
    appProvider.disposeWebSocket();
    super.dispose();
  }

  void _onTableStatusChanged() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final lastChange = appProvider.lastTableStatusChange;
    if (lastChange != null) {
      final tableName = lastChange['tableName'] ?? 'Table';
      final status = lastChange['status'];
      final message = status == 'OCCUPEE'
          ? '$tableName est maintenant occupée'
          : '$tableName est maintenant libre';

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: status == 'OCCUPEE' ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      appProvider.consumeLastTableStatusChange();
    }
  }

  // ==========================================
  // AVATAR (Cloudinary)
  // ==========================================
  Widget _buildProfileAvatar(User? user) {
    final imageUrl = user?.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF4caf50),
      ),
      child: hasImage
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.white, size: 24),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : const SizedBox.shrink(),
              ),
            )
          : const Icon(Icons.person, color: Colors.white, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final cartCount = appProvider.cartCount;
    final user = appProvider.user;

    const double navHeight = 72;
    const double navMargin = 16;
    const double bottomPadding = navHeight + navMargin * 2 + 8;

    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFf0eded),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Titre
              Text(
                'Leresto',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF006e1c),
                  letterSpacing: -0.01,
                ),
              ),
              Row(
                children: [
                  // Notifications
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.notifications_none,
                          size: 24,
                          color: const Color(0xFF6f7a6b),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF006e1c),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  // Avatar (Cloudinary)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFeae7e7), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildProfileAvatar(user),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      extendBody: true,
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        height: navHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFFf0eded), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              outlinedIcon: Icons.home_outlined,
              filledIcon: Icons.home,
              isSelected: _selectedIndex == 0,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            _buildNavItem(
              outlinedIcon: Icons.restaurant_menu_outlined,
              filledIcon: Icons.restaurant_menu,
              isSelected: _selectedIndex == 1,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            _buildNavItem(
              outlinedIcon: Icons.shopping_cart_outlined,
              filledIcon: Icons.shopping_cart,
              isSelected: _selectedIndex == 2,
              onTap: () => setState(() => _selectedIndex = 2),
              badgeCount: cartCount,
            ),
            _buildNavItem(
              outlinedIcon: Icons.chair_outlined,
              filledIcon: Icons.chair,
              isSelected: _selectedIndex == 3,
              onTap: () => setState(() => _selectedIndex = 3),
            ),
            _buildNavItem(
              outlinedIcon: Icons.account_circle_outlined,
              filledIcon: Icons.account_circle,
              isSelected: _selectedIndex == 4,
              onTap: () => setState(() => _selectedIndex = 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData outlinedIcon,
    required IconData filledIcon,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4caf50).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              size: 28,
              color: isSelected
                  ? const Color(0xFF006e1c)
                  : const Color(0xFF6f7a6b),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
