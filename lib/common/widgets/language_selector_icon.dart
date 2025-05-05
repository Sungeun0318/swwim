// lib/widgets/language_selector_icon.dart
import 'package:flutter/material.dart';

class LanguageSelectorIcon extends StatelessWidget {
  final Function(Locale) onLocaleChange;

  const LanguageSelectorIcon({Key? key, required this.onLocaleChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.language),
      onPressed: () {
        // 언어 선택 다이얼로그 표시
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('언어 선택'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Korean'),
                    onTap: () {
                      onLocaleChange(const Locale('ko', ''));
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    title: const Text('English'),
                    onTap: () {
                      onLocaleChange(const Locale('en', ''));
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    title: const Text('Spanish'),
                    onTap: () {
                      onLocaleChange(const Locale('es', ''));
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    title: const Text('Chinese'),
                    onTap: () {
                      onLocaleChange(const Locale('zh', ''));
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
