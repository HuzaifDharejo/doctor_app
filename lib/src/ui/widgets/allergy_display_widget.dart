import 'package:flutter/material.dart';

class AllergyBadges extends StatelessWidget {
  const AllergyBadges({
    required this.allergies,
    this.onRemove,
    this.maxDisplay = 5,
    super.key,
  });

  final String allergies;
  final Function(String)? onRemove;
  final int maxDisplay;

  @override
  Widget build(BuildContext context) {
    final allergyList = _parseAllergies();
    
    if (allergyList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No allergies documented',
          style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      );
    }

    final displayList = allergyList.take(maxDisplay).toList();
    final hasMore = allergyList.length > maxDisplay;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayList.map((allergy) => Chip(
          label: Text(allergy),
          backgroundColor: Colors.red.shade100,
          labelStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
          avatar: const Icon(Icons.warning_amber, size: 18, color: Colors.red),
          onDeleted: onRemove != null ? () => onRemove!(allergy) : null,
          deleteIcon: onRemove != null ? const Icon(Icons.close, size: 18) : null,
          deleteIconColor: Colors.red,
        )),
        if (hasMore)
          Chip(
            label: Text('+${allergyList.length - maxDisplay} more'),
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(color: Colors.grey.shade700),
          ),
      ],
    );
  }

  List<String> _parseAllergies() {
    if (allergies.isEmpty) return [];
    return allergies
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
  }
}
