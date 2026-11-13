import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EstructuraPrincipal extends StatelessWidget {
  const EstructuraPrincipal({super.key, required this.navegacion});

  final StatefulNavigationShell navegacion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navegacion,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navegacion.currentIndex,
        onDestinationSelected: (indice) => navegacion.goBranch(
          indice,
          initialLocation: indice == navegacion.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Mis publicaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: 'Ofertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
