import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/widget_data.dart';
import '../services/blynk_connection.dart';
import '../services/project_manager.dart';

class WidgetRenderer extends StatelessWidget {
  final WidgetData widgetData;

  const WidgetRenderer({
    super.key,
    required this.widgetData,
  });

  @override
  Widget build(BuildContext context) {
    switch (widgetData.type) {
      case WidgetType.button:
        return ButtonWidget(widgetData: widgetData);
      case WidgetType.slider:
        return SliderWidget(widgetData: widgetData);
      case WidgetType.display:
        return DisplayWidget(widgetData: widgetData);
      case WidgetType.gauge:
        return GaugeWidget(widgetData: widgetData);
      case WidgetType.led:
        return LedWidget(widgetData: widgetData);
      case WidgetType.terminal:
        return TerminalWidget(widgetData: widgetData);
      default:
        return UnknownWidget(widgetData: widgetData);
    }
  }
}

class ButtonWidget extends StatelessWidget {
  final WidgetData widgetData;

  const ButtonWidget({super.key, required this.widgetData});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BlynkConnection, ProjectManager>(
      builder: (context, connection, projectManager, child) {
        final isOn = (widgetData.value ?? 0) != 0;
        final color = Color(widgetData.color ?? 0xFF2196F3);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              final newValue = isOn ? 0 : 1;
              projectManager.updateWidgetValue(widgetData.id, newValue);
              
              if (connection.isConnected && widgetData.pin != null) {
                if (widgetData.pinType == 'virtual') {
                  connection.virtualWrite(widgetData.pin!, newValue.toString());
                } else if (widgetData.pinType == 'digital') {
                  connection.digitalWrite(widgetData.pin!, newValue);
                }
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isOn ? color.withOpacity(0.2) : null,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOn ? Icons.toggle_on : Icons.toggle_off,
                    size: 48,
                    color: isOn ? color : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widgetData.label,
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widgetData.pin != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Pin: ${widgetData.pinType?.toUpperCase()}${widgetData.pin}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SliderWidget extends StatelessWidget {
  final WidgetData widgetData;

  const SliderWidget({super.key, required this.widgetData});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BlynkConnection, ProjectManager>(
      builder: (context, connection, projectManager, child) {
        final value = (widgetData.value ?? 0).toDouble();
        final min = (widgetData.min ?? 0).toDouble();
        final max = (widgetData.max ?? 100).toDouble();
        final color = Color(widgetData.color ?? 0xFF2196F3);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widgetData.label,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  value.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Slider(
                      value: value.clamp(min, max),
                      min: min,
                      max: max,
                      activeColor: color,
                      onChanged: (newValue) {
                        projectManager.updateWidgetValue(widgetData.id, newValue.round());
                        
                        if (connection.isConnected && widgetData.pin != null) {
                          if (widgetData.pinType == 'virtual') {
                            connection.virtualWrite(widgetData.pin!, newValue.round().toString());
                          } else if (widgetData.pinType == 'analog') {
                            connection.analogWrite(widgetData.pin!, newValue.round());
                          }
                        }
                      },
                    ),
                  ),
                ),
                if (widgetData.pin != null)
                  Text(
                    'Pin: ${widgetData.pinType?.toUpperCase()}${widgetData.pin}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DisplayWidget extends StatelessWidget {
  final WidgetData widgetData;

  const DisplayWidget({super.key, required this.widgetData});

  @override
  Widget build(BuildContext context) {
    return Consumer<BlynkConnection>(
      builder: (context, connection, child) {
        String displayValue;
        
        if (connection.isConnected && widgetData.pin != null) {
          final pinKey = '${widgetData.pinType?.toUpperCase()}${widgetData.pin}';
          displayValue = connection.getPinValue(pinKey) ?? widgetData.value?.toString() ?? '--';
        } else {
          displayValue = widgetData.value?.toString() ?? '--';
        }

        final color = Color(widgetData.color ?? 0xFFFF9800);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monitor,
                  size: 32,
                  color: color,
                ),
                const SizedBox(height: 8),
                Text(
                  widgetData.label,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  displayValue,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widgetData.pin != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pin: ${widgetData.pinType?.toUpperCase()}${widgetData.pin}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class GaugeWidget extends StatelessWidget {
  final WidgetData widgetData;

  const GaugeWidget({super.key, required this.widgetData});

  @override
  Widget build(BuildContext context) {
    return Consumer<BlynkConnection>(
      builder: (context, connection, child) {
        final value = (widgetData.value ?? 0).toDouble();
        final min = (widgetData.min ?? 0).toDouble();
        final max = (widgetData.max ?? 100).toDouble();
        final color = Color(widgetData.color ?? 0xFF03A9F4);
        final percentage = ((value - min) / (max - min)).clamp(0.0, 1.0);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widgetData.label,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CustomPaint(
                    painter: GaugePainter(
                      percentage: percentage,
                      color: color,
                    ),
                    child: Center(
                      child: Text(
                        value.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
                if (widgetData.pin != null)
                  Text(
                    'Pin: ${widgetData.pinType?.toUpperCase()}${widgetData.pin}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14 * 0.75,
      3.14 * 1.5,
      false,
      backgroundPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14 * 0.75,
      3.14 * 1.5 * percentage,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}

class LedWidget extends StatelessWidget {
  final WidgetData widgetData;

  const LedWidget({super.key, required this.widgetData});

  @override
  Widget build(BuildContext context) {
    return Consumer<BlynkConnection>(
      builder: (context, connection, child) {
        final isOn = (widgetData.value ?? 0) != 0;
        final color = Color(widgetData.color ?? 0xFF4CAF50);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOn ? color : Colors.grey.shade300,
                    boxShadow: isOn
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widgetData.label,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widgetData.pin != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pin: ${widgetData.pinType?.toUpperCase()}${widgetData.pin}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class TerminalWidget extends StatelessWidget {
  final WidgetData widgetData;

  const TerminalWidget({super.key, required this.widgetData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  widgetData.label,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widgetData.value?.toString() ?? '',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UnknownWidget extends StatelessWidget {
  final WidgetData widgetData;

  const UnknownWidget({super.key, required this.widgetData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              widgetData.label,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Type: ${widgetData.type.toString().split('.').last}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
