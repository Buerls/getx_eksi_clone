// lib/app/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ana Renkler (Örnek - Kendi renklerinizi seçin)
  static const Color primaryColor = Colors.teal; // Ana renk (AppBar, Butonlar vb.)
  static const Color secondaryColor = Colors.amber; // Vurgu rengi (FAB vb.)
  static const Color backgroundColor = Color(0xFFF5F5F5); // Genel arka plan (hafif gri)
  static const Color surfaceColor = Colors.white; // Kartların vb. arka planı
  static const Color errorColor = Colors.redAccent;

  // Açık Tema Tanımı
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, // Material 3 kullanmak modern bir görünüm sağlar
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor, // Ana renkten diğer renkleri türet
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        error: errorColor,
      ),

      // Yazı Tipi Teması (Google Fonts ile)
      textTheme: GoogleFonts.latoTextTheme( // Seçtiğiniz bir font (örn: Lato, Roboto, Open Sans)
        ThemeData.light().textTheme, // Mevcut açık tema yazı tiplerini temel al
      ).copyWith( // Gerekirse belirli stilleri özelleştirin
        headlineMedium: GoogleFonts.montserrat( // Başlıklar için farklı bir font?
          fontWeight: FontWeight.w600,
          // fontSize: 24, // Gerekirse boyut ayarı
        ),
        titleLarge: GoogleFonts.montserrat( // Daha büyük başlıklar
          fontWeight: FontWeight.w500,
        ),
        // bodyMedium vb. için varsayılan Lato kullanılacak
      ),

      // AppBar Teması
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor, // AppBar arka planı
        foregroundColor: Colors.white, // AppBar ikon ve yazı rengi
        elevation: 1.0, // Hafif bir gölge
        centerTitle: true, // Başlığı ortala (web için)
      ),

      // Kart Teması
      cardTheme: CardTheme(
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), // Hafif yuvarlak köşeler
        ),
        color: surfaceColor, // Kart arka planı
      ),

      // Input Alanı Teması
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder( // Varsayılan kenarlık stili
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: primaryColor, width: 2.0), // Odaklanınca ana renk
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // İç boşluk
      ),

      // Buton Temaları
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Arka plan
          foregroundColor: Colors.white, // Yazı rengi
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold), // Buton yazı stili
        ),
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor, // Yazı rengi
            textStyle: GoogleFonts.lato(fontWeight: FontWeight.w600),
          )
      ),

      // ListTile Teması (Opsiyonel)
      listTileTheme: ListTileThemeData(
        // tileColor: surfaceColor, // Arka plan rengi
        // dense: true, // Daha sıkışık görünüm
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // ListTile'a da şekil verebiliriz
      ),

      // Web için daha kompakt bir görünüm (opsiyonel)
      visualDensity: VisualDensity.comfortable, // veya .compact

      // Diğer tema ayarları...
    );
  }

// Koyu Tema Tanımı (İsteğe bağlı)
// static ThemeData get darkTheme { ... }
}