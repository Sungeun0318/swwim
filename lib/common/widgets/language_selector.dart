// lib/widgets/language_selector.dart
import 'package:flutter/material.dart';

class LanguageSelector extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  const LanguageSelector({Key? key, required this.onLocaleChange}) : super(key: key);

  @override
  _LanguageSelectorState createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String _selectedLanguage = 'Korean';

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedLanguage,
      icon: const Icon(Icons.language, color: Colors.white),
      underline: Container(),
      dropdownColor: Colors.blue,
      onChanged: (String? newValue) {
        setState(() {
          _selectedLanguage = newValue!;
        });
        if (newValue == 'Korean') {
          widget.onLocaleChange(const Locale('ko', ''));
        } else if (newValue == 'English') {
          widget.onLocaleChange(const Locale('en', ''));
        } else if (newValue == 'Spanish') {
          widget.onLocaleChange(const Locale('es', ''));
        } else if (newValue == 'Chinese') {
          widget.onLocaleChange(const Locale('zh', ''));
        }
      },
      items: <String>['Korean', 'Spanish', 'English', 'Chinese']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }
}
