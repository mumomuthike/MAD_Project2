import 'package:flutter/material.dart';

class AlbumArt extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String placeholderIcon;

  const AlbumArt({
    super.key,
    this.imageUrl,
    this.size = 48,
    this.placeholderIcon = 'music_note_rounded',
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getIcon(), color: primary, size: size * 0.5),
            );
          },
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_getIcon(), color: primary, size: size * 0.5),
    );
  }

  IconData _getIcon() {
    switch (placeholderIcon) {
      case 'album':
        return Icons.album_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }
}
