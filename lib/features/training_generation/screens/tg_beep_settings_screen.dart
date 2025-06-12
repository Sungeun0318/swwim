// tg_beep_settings_screen.dart (비프 설정 팝업)

import 'package:flutter/material.dart';

class TGBeepSettingsDialog extends StatefulWidget {
  final String selectedSound;
  final int numPeople;

  const TGBeepSettingsDialog({
    Key? key,
    required this.selectedSound,
    required this.numPeople,
  }) : super(key: key);

  @override
  _TGBeepSettingsDialogState createState() => _TGBeepSettingsDialogState();
}

class _TGBeepSettingsDialogState extends State<TGBeepSettingsDialog> {
  late String _sound;
  late int _people;

  @override
  void initState() {
    super.initState();
    _sound = widget.selectedSound;
    _people = widget.numPeople;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("비프 설정"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text("사운드 선택: "),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sound,
                items: const [
                  DropdownMenuItem(
                    value: "ppppig.mp3",
                    child: Text("ppppig.mp3"),
                  ),
                  DropdownMenuItem(
                    value: "Take your marks.mp3",
                    child: Text("Take your marks.mp3"),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _sound = val;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text("훈련 인원 선택: "),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_people > 1) _people--;
                  });
                },
                icon: const Icon(Icons.remove_circle, color: Colors.pink),
              ),
              Text("$_people"),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_people < 30) _people++;
                  });
                },
                icon: const Icon(Icons.add_circle, color: Colors.pink),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, {
              'sound': _sound,
              'people': _people,
            });
          },
          child: const Text("확인"),
        ),
      ],
    );
  }
}
