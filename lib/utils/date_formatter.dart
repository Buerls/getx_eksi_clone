// lib/utils/date_formatter.dart
import 'package:intl/intl.dart';

String formatDate(DateTime dateTime) {
  // Örneğin: 30 Nis 2025 12:22
  final formatter = DateFormat('dd MMM yyyy HH:mm', 'tr_TR');
  try {
    // Tarihi cihazın lokal saatine çevirip formatla
    return formatter.format(dateTime.toLocal());
  } catch (e) {
    // Hata olursa orijinal string'i veya varsayılan bir değeri dön
    print("Date formatting error: $e");
    return dateTime.toIso8601String(); // Veya sadece ''
  }
}