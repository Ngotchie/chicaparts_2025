import 'package:flutter/material.dart';

class EquipmentsList extends StatelessWidget {
  final Map<String, List<String>> equipments;

  const EquipmentsList({super.key, required this.equipments});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: equipments.entries.map((entry) {
          String category = entry.key;
          List<String> items = entry.value;

          if (items.isEmpty) {
            return Container(); // Si pas d'équipements, ne pas afficher la catégorie
          }

          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: ExpansionTile(
              leading: Icon(_getCategoryIcon(category),
                  color: Colors.blue), // ✅ Icône dynamique
              title: Text(category,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              children: items.map((item) {
                return ListTile(
                  leading: const Icon(Icons.check,
                      color: Colors
                          .green), // ✅ Icône de validation pour chaque équipement
                  title: Text(item, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 🔹 Fonction qui retourne une icône selon la catégorie
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case "parking":
        return Icons.local_parking;
      case "chambre":
        return Icons.bed;
      case "salon":
        return Icons.chair;
      case "cuisine":
        return Icons.kitchen;
      case "high-tech":
        return Icons.tv;
      case "salle de bain":
        return Icons.bathtub;
      case "nettoyage":
        return Icons.cleaning_services;
      case "sécurité":
        return Icons.security;
      case "extérieur":
        return Icons.park;
      case "connectivité":
        return Icons.wifi;
      default:
        return Icons.category; // Icône par défaut
    }
  }
}
