import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme myTextTheme = const TextTheme(
  headlineMedium: TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
  ),
  bodyMedium: TextStyle(
    fontSize: 18.0,
    // fontWeight: FontWeight.w300,
  ),
  bodySmall: TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: Colors.grey,
  ),
);

ThemeData AppTheme = ThemeData(
    textTheme: GoogleFonts.robotoTextTheme(myTextTheme).copyWith(
        headlineMedium: GoogleFonts.lexend(),
        bodyMedium: GoogleFonts.lexend()));
