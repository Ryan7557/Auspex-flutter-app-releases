import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../themes.dart';

class CustomAppbar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppbar({super.key});

  static final _appBarTitle = Text(
    'AUSPEX',
    style: GoogleFonts.vt323(fontSize: 35, fontWeight: FontWeight.bold),
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return AppBar(
      title: _appBarTitle,
      actions: [
        IconButton(
          icon: Icon(
            Icons.lightbulb,
            size: 30,
            color:
                themeProvider.themeMode == ThemeMode.light
                    ? Colors.black
                    : Colors.yellow,
          ),
          onPressed: () {
            themeProvider.toggleTheme(
              themeProvider.themeMode == ThemeMode.light,
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
