import 'package:flutter/material.dart';
import '../models/dashboard.dart';
import '../models/tab.dart';
import '../models/widget_model.dart';
import '../services/blynk_service_simple.dart';
import '../widgets/blynk_widget_renderer.dart';

class BlynkDashboardScreen extends StatefulWidget {
  final Dashboard dashboard;
  final BlynkServiceSimple blynkService;

  const BlynkDashboardScreen({
    super.key,
    required this.dashboard,
    required this.blynkService,
  });

  @override
  State<BlynkDashboardScreen> createState() => _BlynkDashboardScreenState();
}

class _BlynkDashboardScreenState extends State<BlynkDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.dashboard.tabs.isEmpty ? 1 : widget.dashboard.tabs.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    // Lắng nghe thay đổi pin values từ BlynkService
    widget.blynkService.addListener(_onPinValueChanged);
  }

  @override
  void dispose() {
    widget.blynkService.removeListener(_onPinValueChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onPinValueChanged() {
    setState(() {
      // Update widgets với pin values mới
      final pinValues = widget.blynkService.pinValues;
      for (var widget in widget.dashboard.widgets) {
        if (widget.dataStream != null) {
          final pinKey = widget.dataStream!.pinKey;
          if (pinValues.containsKey(pinKey)) {
            widget.updateValue(pinValues[pinKey]!);
          }
        }
      }
    });
  }

  TabModel? get currentTab {
    if (widget.dashboard.tabs.isEmpty) return null;
    return widget.dashboard.tabs[_currentTabIndex];
  }

  List<WidgetModel> get currentWidgets {
    if (currentTab == null) {
      return widget.dashboard.widgets;
    }
    return widget.dashboard.getWidgetsForTab(currentTab!.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dashboard.name),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        bottom: widget.dashboard.tabs.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.blueAccent,
                tabs: widget.dashboard.tabs
                    .map((tab) => Tab(text: tab.label))
                    .toList(),
              ),
        actions: [
          if (currentTab != null) _buildDeviceSelector(),
        ],
      ),
      body: widget.dashboard.tabs.isEmpty
          ? _buildWidgetGrid()
          : TabBarView(
              controller: _tabController,
              children: widget.dashboard.tabs
                  .map((tab) => _buildWidgetGrid())
                  .toList(),
            ),
    );
  }

  Widget _buildDeviceSelector() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: DropdownButton<int>(
        value: currentTab?.selectedDeviceId,
        hint: const Text('Chọn Device', style: TextStyle(color: Colors.white)),
        dropdownColor: Colors.blueGrey[700],
        style: const TextStyle(color: Colors.white),
        underline: Container(),
        icon: const Icon(Icons.devices, color: Colors.white),
        items: widget.dashboard.deviceIds.map((deviceId) {
          return DropdownMenuItem<int>(
            value: deviceId,
            child: Text('Device $deviceId'),
          );
        }).toList(),
        onChanged: (deviceId) {
          setState(() {
            if (currentTab != null) {
              currentTab!.selectedDeviceId = deviceId;
            }
          });
        },
      ),
    );
  }

  Widget _buildWidgetGrid() {
    if (currentWidgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.widgets_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có widget',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: currentWidgets.length,
      itemBuilder: (context, index) {
        final widget = currentWidgets[index];
        return BlynkWidgetRenderer(
          widget: widget,
          blynkService: this.widget.blynkService,
        );
      },
    );
  }
}
