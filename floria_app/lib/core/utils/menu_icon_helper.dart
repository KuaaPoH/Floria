import 'package:flutter/material.dart';

class MenuIconPair {
  final IconData normal;
  final IconData active;
  const MenuIconPair(this.normal, this.active);
}

class MenuIconHelper {
  static MenuIconPair resolve(String? iconName) {
    switch (iconName) {
      case 'Home':
        return const MenuIconPair(Icons.home_outlined, Icons.home);
      case 'Eco':
      case 'Leaf':
      case 'Flower2':
        return const MenuIconPair(Icons.eco_outlined, Icons.eco);
      case 'CameraAlt':
      case 'Camera':
        return const MenuIconPair(Icons.camera_alt_outlined, Icons.camera_alt);
      case 'ShoppingBag':
      case 'Store':
        return const MenuIconPair(Icons.shopping_bag_outlined, Icons.shopping_bag);
      case 'Person':
      case 'Users':
        return const MenuIconPair(Icons.person_outline, Icons.person);
      case 'Sparkles':
      case 'Bot':
        return const MenuIconPair(Icons.auto_awesome_outlined, Icons.auto_awesome);
      case 'BookOpen':
        return const MenuIconPair(Icons.menu_book_outlined, Icons.menu_book);
      case 'BellRing':
        return const MenuIconPair(Icons.notifications_outlined, Icons.notifications);
      case 'Heart':
        return const MenuIconPair(Icons.favorite_outline, Icons.favorite);
      case 'Compass':
        return const MenuIconPair(Icons.explore_outlined, Icons.explore);
      case 'LayoutDashboard':
        return const MenuIconPair(Icons.dashboard_outlined, Icons.dashboard);
      case 'Settings2':
        return const MenuIconPair(Icons.settings_outlined, Icons.settings);
      default:
        return const MenuIconPair(Icons.circle_outlined, Icons.circle);
    }
  }
}
