import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SortOptions extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortSelected;

  const SortOptions({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(
              'Sort by Date',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: currentSort == 'date' ? const Icon(Icons.check) : null,
            onTap: () {
              onSortSelected('date');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.title),
            title: Text(
              'Sort by Title',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: currentSort == 'title' ? const Icon(Icons.check) : null,
            onTap: () {
              onSortSelected('title');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
