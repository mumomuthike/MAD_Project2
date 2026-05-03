import 'package:flutter/material.dart';

class VibzBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isHomeScreen;

  const VibzBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.isHomeScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF7A00);

    final tabs = isHomeScreen
        ? [
            {'icon': Icons.home_rounded, 'label': 'Home'},
            {'icon': Icons.person_rounded, 'label': 'Profile'},
          ]
        : [
            {'icon': Icons.queue_music_rounded, 'label': 'Queue'},
            {'icon': Icons.music_note_rounded, 'label': 'Now'},
            {'icon': Icons.chat_bubble_rounded, 'label': 'Chat'},
            {'icon': Icons.bar_chart_rounded, 'label': 'Stats'},
            {'icon': Icons.person_rounded, 'label': 'You'},
          ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isSelected = selectedIndex == index;
          // Get the IconData from the map
          final iconData = tab['icon'] as IconData;

          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    iconData, // Now using the IconData correctly
                    color: isSelected ? activeColor : Colors.white54,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      color: isSelected ? activeColor : Colors.white54,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
