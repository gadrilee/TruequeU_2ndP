import 'package:flutter/material.dart';

import '../tema.dart';
import '../utilidades/etiquetas.dart';

/// Buscador por título + menús de filtros + chips de los filtros activos.
/// No guarda nada: avisa con callbacks y la pantalla decide qué hacer.
/// Los nombres de filtro son: 'busqueda', 'categoria', 'condicion' y 'disponibilidad'.
class FiltrosFeed extends StatelessWidget {
  const FiltrosFeed({
    super.key,
    required this.buscarCtrl,
    required this.busqueda,
    required this.categoria,
    required this.condicion,
    required this.disponibilidad,
    required this.alBuscar,
    required this.alElegir,
    required this.alQuitar,
    required this.alQuitarTodos,
  });

  final TextEditingController buscarCtrl;
  final String busqueda; // texto de búsqueda que ya se aplicó
  final String? categoria;
  final String? condicion;
  final String? disponibilidad;
  final VoidCallback alBuscar;
  final void Function(String filtro, String valor) alElegir;
  final void Function(String filtro) alQuitar;
  final VoidCallback alQuitarTodos;

  bool get _hayFiltros =>
      busqueda.isNotEmpty ||
      categoria != null ||
      condicion != null ||
      disponibilidad != null;

  /// Botón de menú para un filtro (categoría, condición o disponibilidad)
  Widget _menuFiltro(String titulo, String filtro, Map<String, String> opciones) {
    return PopupMenuButton<String>(
      tooltip: 'Filtrar por ${titulo.toLowerCase()}',
      onSelected: (valor) => alElegir(filtro, valor),
      itemBuilder: (ctx) => [
        for (final opcion in opciones.entries)
          PopupMenuItem<String>(value: opcion.key, child: Text(opcion.value)),
      ],
      child: Chip(
        avatar: const Icon(Icons.tune, size: 16),
        label: Text(titulo),
        backgroundColor: TemaTruequeU.blanco,
        shape: const StadiumBorder(side: BorderSide(color: TemaTruequeU.borde)),
      ),
    );
  }

  static final buscadorBorde = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radios.r28),
    borderSide: const BorderSide(color: TemaTruequeU.borde),
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Espacios.e20, Espacios.e12, Espacios.e20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: buscarCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => alBuscar(),
                decoration: InputDecoration(
                  hintText: 'Buscar objetos',
                  isDense: true,
                  border: buscadorBorde,
                  enabledBorder: buscadorBorde,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Buscar',
                    onPressed: alBuscar,
                  ),
                ),
              ),
              const SizedBox(height: Espacios.e8),
              Wrap(
                spacing: Espacios.e8,
                runSpacing: Espacios.e4,
                children: [
                  _menuFiltro('Categoría', 'categoria', etiquetasCategoria),
                  _menuFiltro('Condición', 'condicion', etiquetasCondicion),
                  _menuFiltro('Disponibilidad', 'disponibilidad', etiquetasDisponibilidad),
                ],
              ),
              // Filtros activos: cada uno se puede quitar con la X
              if (_hayFiltros) ...[
                const SizedBox(height: Espacios.e4),
                Wrap(
                  spacing: Espacios.e8,
                  runSpacing: Espacios.e4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (busqueda.isNotEmpty)
                      InputChip(
                        label: Text('Título: $busqueda'),
                        onDeleted: () => alQuitar('busqueda'),
                      ),
                    if (categoria != null)
                      InputChip(
                        label: Text('Categoría: ${etiquetasCategoria[categoria]}'),
                        onDeleted: () => alQuitar('categoria'),
                      ),
                    if (condicion != null)
                      InputChip(
                        label: Text('Condición: ${etiquetasCondicion[condicion]}'),
                        onDeleted: () => alQuitar('condicion'),
                      ),
                    if (disponibilidad != null)
                      InputChip(
                        label: Text(
                          'Disponibilidad: ${etiquetasDisponibilidad[disponibilidad]}',
                        ),
                        onDeleted: () => alQuitar('disponibilidad'),
                      ),
                    TextButton(
                      onPressed: alQuitarTodos,
                      child: const Text('Quitar todos'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
