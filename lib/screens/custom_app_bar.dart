import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sort_options.dart'; // Make sure this import path is correct

AppBar buildCustomAppBar(BuildContext context, String currentSort, Function(String) onSortSelected) {
  return AppBar(
    backgroundColor: const Color(0xFF900C3F),
    title: Text(
      'Namaste Messenger',
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    ),
    leading: Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.filter_alt, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SortOptions(
              currentSort: currentSort,
              onSortSelected: onSortSelected,
            ),
          );
        },
      ),
    ],
  );
}
