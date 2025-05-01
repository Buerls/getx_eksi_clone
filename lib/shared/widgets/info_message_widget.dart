// lib/app/shared/widgets/info_message_widget.dart
import 'package:flutter/material.dart';

class InfoMessageWidget extends StatelessWidget {
  /// Gösterilecek ana mesaj.
  final String message;

  /// Gösterilecek ikon (varsayılan: bilgi ikonu).
  final IconData icon;

  /// İkon rengi (varsayılan: gri). 'showError' true ise kırmızı kullanılır.
  final Color iconColor;

  /// Hata durumu mu? (true ise kırmızı renk ve hata ikonu kullanılır).
  final bool showError;

  /// Eğer bir 'Retry' butonu gösterilecekse, tıklandığında çağrılacak fonksiyon.
  final VoidCallback? onRetry;

  /// Ekranın ortasında bilgi/hata/boş durum mesajlarını göstermek için widget.
  const InfoMessageWidget({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded, // Varsayılan ikon
    this.iconColor = Colors.grey,
    this.showError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Hata durumuna göre ikon ve renk belirle
    final Color effectiveIconColor = showError ? Theme.of(context).colorScheme.error : iconColor;
    final IconData effectiveIcon = showError ? Icons.error_outline_rounded : icon;

    return Center( // İçeriği her zaman ortala
      child: Padding(
        padding: const EdgeInsets.all(25.0), // Kenarlardan boşluk
        child: Column(
          mainAxisSize: MainAxisSize.min, // İçerik kadar yer kapla
          mainAxisAlignment: MainAxisAlignment.center, // Dikeyde de ortala
          children: [
            // İkon
            Icon(
              effectiveIcon,
              size: 50, // İkon boyutu
              color: effectiveIconColor,
            ),
            const SizedBox(height: 16), // İkon ile metin arasına boşluk

            // Mesaj Metni
            Text(
              message,
              textAlign: TextAlign.center, // Metni ortala
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: showError ? Theme.of(context).colorScheme.error : null, // Hata ise kırmızı
              ),
            ),

            // Yeniden Deneme Butonu (eğer onRetry tanımlıysa)
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                // Buton stilini tema ile uyumlu hale getirebilirsin
                // style: ElevatedButton.styleFrom(
                //   backgroundColor: effectiveIconColor, // Veya tema rengi
                // ),
              )
            ]
          ],
        ),
      ),
    );
  }
}