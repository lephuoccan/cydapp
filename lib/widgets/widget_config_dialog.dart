import 'package:flutter/material.dart';
import '../models/widget_data.dart';

class WidgetConfigDialog extends StatefulWidget {
  final WidgetData? widget;
  final Function(WidgetData) onSave;

  const WidgetConfigDialog({
    super.key,
    this.widget,
    required this.onSave,
  });

  @override
  State<WidgetConfigDialog> createState() => _WidgetConfigDialogState();
}

class _WidgetConfigDialogState extends State<WidgetConfigDialog> {
  late TextEditingController _labelController;
  late WidgetType _selectedType;
  late String _selectedPinType;
  late int _selectedPin;
  late Color _selectedColor;
  late String _mode;
  late double _min;
  late double _max;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.widget?.label ?? '');
    _selectedType = widget.widget?.type ?? WidgetType.button;
    _selectedPinType = widget.widget?.pinType ?? 'virtual';
    _selectedPin = widget.widget?.pin ?? 0;
    _selectedColor = Color(widget.widget?.color ?? 0xFF2196F3);
    _mode = widget.widget?.mode ?? 'switch';
    _min = (widget.widget?.min ?? 0).toDouble();
    _max = (widget.widget?.max ?? 100).toDouble();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.widget == null ? 'Add Widget' : 'Edit Widget'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widget Type
            DropdownButtonFormField<WidgetType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Widget Type',
                border: OutlineInputBorder(),
              ),
              items: [
                WidgetType.button,
                WidgetType.slider,
                WidgetType.display,
                WidgetType.gauge,
                WidgetType.led,
                WidgetType.terminal,
              ].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getWidgetTypeName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),
            const SizedBox(height: 16),

            // Label
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Pin Type
            DropdownButtonFormField<String>(
              value: _selectedPinType,
              decoration: const InputDecoration(
                labelText: 'Pin Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'virtual', child: Text('Virtual')),
                DropdownMenuItem(value: 'digital', child: Text('Digital')),
                DropdownMenuItem(value: 'analog', child: Text('Analog')),
              ],
              onChanged: (value) {
                setState(() => _selectedPinType = value!);
              },
            ),
            const SizedBox(height: 16),

            // Pin Number
            TextField(
              decoration: const InputDecoration(
                labelText: 'Pin Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: _selectedPin.toString()),
              onChanged: (value) {
                _selectedPin = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),

            // Button Mode
            if (_selectedType == WidgetType.button) ...[
              DropdownButtonFormField<String>(
                value: _mode,
                decoration: const InputDecoration(
                  labelText: 'Button Mode',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'switch', child: Text('Switch')),
                  DropdownMenuItem(value: 'push', child: Text('Push')),
                ],
                onChanged: (value) {
                  setState(() => _mode = value!);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Min/Max for Slider and Gauge
            if (_selectedType == WidgetType.slider || _selectedType == WidgetType.gauge) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Min Value',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: _min.toStringAsFixed(0)),
                      onChanged: (value) {
                        _min = double.tryParse(value) ?? 0;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Max Value',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: _max.toStringAsFixed(0)),
                      onChanged: (value) {
                        _max = double.tryParse(value) ?? 100;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Color Picker
            const Text('Color', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.blue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.orange,
                Colors.amber,
              ].map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            final newWidget = WidgetData(
              id: widget.widget?.id ?? DateTime.now().millisecondsSinceEpoch,
              type: _selectedType,
              label: _labelController.text,
              pin: _selectedPin,
              pinType: _selectedPinType,
              mode: _mode,
              color: _selectedColor.value,
              min: _min.toInt(),
              max: _max.toInt(),
              x: widget.widget?.x ?? 0,
              y: widget.widget?.y ?? 0,
              width: widget.widget?.width ?? 2,
              height: widget.widget?.height ?? 2,
            );
            widget.onSave(newWidget);
            Navigator.of(context).pop();
          },
          child: const Text('SAVE'),
        ),
      ],
    );
  }

  String _getWidgetTypeName(WidgetType type) {
    switch (type) {
      case WidgetType.button:
        return 'Button';
      case WidgetType.slider:
        return 'Slider';
      case WidgetType.display:
        return 'Display';
      case WidgetType.gauge:
        return 'Gauge';
      case WidgetType.led:
        return 'LED';
      case WidgetType.terminal:
        return 'Terminal';
      default:
        return type.toString().split('.').last;
    }
  }
}
