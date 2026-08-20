import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/wheel_preset.dart';
import '../services/storage_service.dart';
import '../widgets/generic_wheel_dialog.dart';

const _examplePresets = [
  WheelPreset(
    id: 'example-challenges',
    name: 'Zufalls-Herausforderungen',
    entries: [
      'Nur U21-Spieler',
      'Kein Kauf erlaubt',
      'Pokalfinale-Regeln',
      'Auswaertstrikot Pflicht',
      'Nur Systemwechsel',
    ],
  ),
  WheelPreset(
    id: 'example-formations',
    name: 'Formations-Zufall',
    entries: ['4-3-3', '4-4-2', '3-5-2', '4-2-3-1', '5-3-2'],
  ),
];

class CustomWheelScreen extends StatefulWidget {
  const CustomWheelScreen({super.key, required this.onBack, required this.strings});

  final VoidCallback onBack;
  final AppStrings strings;

  @override
  State<CustomWheelScreen> createState() => _CustomWheelScreenState();
}

class _CustomWheelScreenState extends State<CustomWheelScreen> {
  final StorageService _storage = StorageService();
  List<WheelPreset> _presets = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final loaded = await _storage.loadWheelPresets();
    if (loaded.isEmpty) {
      await _storage.saveWheelPresets(_examplePresets);
      if (!mounted) {
        return;
      }
      setState(() {
        _presets = _examplePresets;
        _loading = false;
      });
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _presets = loaded;
      _loading = false;
    });
  }

  Future<void> _persist(List<WheelPreset> presets) async {
    await _storage.saveWheelPresets(presets);
    setState(() {
      _presets = presets;
    });
  }

  Future<void> _deletePreset(WheelPreset preset) async {
    final updated = _presets.where((entry) => entry.id != preset.id).toList();
    await _persist(updated);
  }

  Future<void> _spinPreset(WheelPreset preset) async {
    await showGenericWheelDialog(
      context: context,
      entries: preset.entries,
      title: preset.name,
      strings: widget.strings,
    );
  }

  Future<void> _addPreset() async {
    final nameController = TextEditingController();
    final entriesController = TextEditingController();
    final strings = widget.strings;

    final created = await showDialog<WheelPreset>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.newWheelDialogTitle),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: strings.nameLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: entriesController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: strings.entriesLabel,
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final entries = entriesController.text
                    .split('\n')
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty)
                    .toList();

                if (name.isEmpty || entries.length < 2) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  WheelPreset(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    entries: entries,
                  ),
                );
              },
              child: Text(strings.createButton),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    entriesController.dispose();

    if (created != null) {
      await _persist([..._presets, created]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.customWheelTitle),
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPreset,
        icon: const Icon(Icons.add),
        label: Text(strings.newWheelFab),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _presets.isEmpty
              ? Center(child: Text(strings.noWheelsYet))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: _presets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    return Card(
                      child: ListTile(
                        title: Text(preset.name),
                        subtitle: Text(strings.entriesCount(preset.entries.length)),
                        onTap: () => _spinPreset(preset),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _spinPreset(preset),
                              icon: const Icon(Icons.rotate_right),
                              tooltip: strings.spinTooltip,
                            ),
                            IconButton(
                              onPressed: () => _deletePreset(preset),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: strings.deleteTooltip,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
