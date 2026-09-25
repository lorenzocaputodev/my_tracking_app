import 'package:flutter/material.dart';

/// Icone con un significato nell'app: lo stesso concetto usa sempre la
/// stessa icona, e concetti diversi non si somigliano (la scorta non deve
/// sembrare l'archivio).
abstract final class AppIcons {
  /// Prodotto con scorta: la confezione, una pila di unita'.
  static const IconData stock = Icons.layers_rounded;

  /// Prodotto senza scorta: conta solo gli utilizzi.
  static const IconData noStock = Icons.show_chart_rounded;

  /// Prodotto in generale, o piu' prodotti insieme.
  static const IconData product = Icons.category_rounded;

  static const IconData archive = Icons.archive_outlined;

  /// Quantita' registrate in un periodo.
  static const IconData total = Icons.tag_rounded;
}
