import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/blynk_service_simple.dart';
import '../services/profile_parser.dart';
import '../models/dashboard.dart';
import '../models/widget_model.dart';

class DashboardViewScreen extends StatefulWidget {
  const DashboardViewScreen({Key? key}) : super(key: key);

  @override
  State<DashboardViewScreen> createState() => _DashboardViewScreenState();
}

class _DashboardViewScreenState extends State<DashboardViewScreen> {
  Dashboard? _selectedDashboard;
  bool _isReconnecting = false;
  String? _lastProfileHash; // Track profile changes to avoid unnecessary rebuilds

  @override
  void initState() {
    super.initState();
    // Check connection and auto-reconnect if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnectionAndReconnect();
    });
  }

  Future<void> _checkConnectionAndReconnect() async {
    final blynk = context.read<BlynkServiceSimple>();
    
    // If already connected, nothing to do
    if (blynk.isConnected) {
      return;
    }
    
    // Try to reconnect with saved credentials
    setState(() => _isReconnecting = true);
    
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('blynk_email');
    final password = prefs.getString('blynk_password');
    final serverIp = prefs.getString('blynk_server_ip');
    final serverPort = prefs.getString('blynk_server_port');
    
    if (email != null && password != null && serverIp != null && serverPort != null) {
      final success = await blynk.connect(
        serverIp,
        int.tryParse(serverPort) ?? 9443,
        email,
        password,
      );
      
      if (success) {
        debugPrint('✅ Auto-reconnect successful');
      } else {
        debugPrint('❌ Auto-reconnect failed, redirecting to login');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    } else {
      debugPrint('❌ No saved credentials, redirecting to login');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
    
    setState(() => _isReconnecting = false);
  }

  @override
  void dispose() {
    // Deactivate dashboard when leaving screen
    if (_selectedDashboard != null) {
      final blynk = context.read<BlynkServiceSimple>();
      debugPrint('🔴 Deactivating dashboard ${_selectedDashboard!.id} (dispose)');
      blynk.deactivateDashboard(_selectedDashboard!.id);
    }
    super.dispose();
  }

  void _selectDashboard(Dashboard dashboard, BlynkServiceSimple blynk) {
    if (_selectedDashboard?.id == dashboard.id) return;
    
    // Deactivate old dashboard
    if (_selectedDashboard != null) {
      debugPrint('🔴 Deactivating old dashboard ${_selectedDashboard!.id}');
      blynk.deactivateDashboard(_selectedDashboard!.id);
    }
    
    setState(() {
      _selectedDashboard = dashboard;
    });
    
    // Activate new dashboard
    debugPrint('🟢 Activating new dashboard ${dashboard.id}');
    blynk.setActiveDashboard(dashboard.id);
    blynk.activateDashboard(dashboard.id);
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboards'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // Clear saved credentials
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('blynk_email');
              await prefs.remove('blynk_password');
              await prefs.remove('blynk_server_ip');
              await prefs.remove('blynk_server_port');
              debugPrint('🔓 Credentials cleared');
              
              // Disconnect
              final blynk = context.read<BlynkServiceSimple>();
              blynk.disconnect();
              
              // Navigate to login
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Consumer<BlynkServiceSimple>(
        builder: (context, blynk, child) {
          // Show reconnecting indicator
          if (_isReconnecting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Reconnecting...'),
                ],
              ),
            );
          }
          
          // Show connection status if disconnected
          if (!blynk.isConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  const Text('Connection lost', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(blynk.lastError, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _checkConnectionAndReconnect,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reconnect'),
                  ),
                ],
              ),
            );
          }
          
          final profileJson = blynk.profileJson;
          
          if (profileJson == null || profileJson.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No profile loaded'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await blynk.loadProfile();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Load Profile'),
                  ),
                ],
              ),
            );
          }

          final dashboards = ProfileParser.parseProfileToDashboards(profileJson);

          if (dashboards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dashboard_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No dashboards found in profile'),
                  const SizedBox(height: 8),
                  Text('Profile length: ${profileJson.length} chars', 
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('📋 Full profile JSON:\n$profileJson');
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Print Full JSON to Console'),
                  ),
                ],
              ),
            );
          }

          // Auto-select first dashboard if none selected
          // OR update selected dashboard to latest version if profile reloaded
          
          // Track profile hash to only update when profile actually changes
          final currentHash = profileJson.hashCode.toString();
          final profileChanged = currentHash != _lastProfileHash;
          
          if (_selectedDashboard == null && dashboards.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedDashboard = dashboards.first;
                _lastProfileHash = currentHash;
              });
              // Set active dashboard and activate it
              debugPrint('🟢 Auto-activating first dashboard ${dashboards.first.id}');
              blynk.setActiveDashboard(dashboards.first.id);
              blynk.activateDashboard(dashboards.first.id);
            });
          } else if (_selectedDashboard != null && dashboards.isNotEmpty && profileChanged) {
            // ONLY update if profile actually changed (avoid infinite loop)
            final updatedDashboard = dashboards.firstWhere(
              (d) => d.id == _selectedDashboard!.id,
              orElse: () => dashboards.first,
            );
            
            // Check if switching to different dashboard (before setState)
            final bool isDifferentDashboard = updatedDashboard.id != _selectedDashboard!.id;
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedDashboard = updatedDashboard;
                _lastProfileHash = currentHash;
              });
              
              // Log update
              if (isDifferentDashboard) {
                debugPrint('🔄 Switched to dashboard (id: ${updatedDashboard.id})');
              } else {
                debugPrint('🔄 Updated dashboard widgets (profile changed)');
              }
            });
          }

          return Row(
            children: [
              // Left sidebar - Dashboard list
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  children: [
                    // Create Dashboard button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement create dashboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Create dashboard - Coming soon!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('New Dashboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // Dashboard list
                    Expanded(
                      child: ListView.builder(
                        itemCount: dashboards.length,
                        itemBuilder: (context, index) {
                          final dashboard = dashboards[index];
                          final isSelected = _selectedDashboard?.id == dashboard.id;

                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.blue.shade50,
                              leading: CircleAvatar(
                                backgroundColor: isSelected 
                                    ? Colors.blue.shade700 
                                    : Colors.grey.shade400,
                                child: Icon(
                                  Icons.dashboard,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                dashboard.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.blue.shade900 : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                '${dashboard.widgets.length} widgets',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: dashboard.isActive
                                  ? Icon(Icons.circle, color: Colors.green.shade600, size: 12)
                                  : null,
                              onTap: () {
                                _selectDashboard(dashboard, blynk);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Right side - Widget display
              Expanded(
                child: _selectedDashboard == null
                    ? const Center(
                        child: Text('Select a dashboard'),
                      )
                    : _buildDashboardContent(blynk, _selectedDashboard!),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardContent(BlynkServiceSimple blynk, Dashboard dashboard) {
    if (dashboard.widgets.isEmpty) {
      return const Center(
        child: Text('No widgets in this dashboard'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dashboard header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.dashboard, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dashboard.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    Text(
                      'ID: ${dashboard.id} • ${dashboard.widgets.length} widgets',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Reload button
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.blue.shade700),
                tooltip: 'Reload dashboard config',
                onPressed: () async {
                  final blynkService = context.read<BlynkServiceSimple>();
                  debugPrint('🔄 Manual reload requested');
                  await blynkService.loadProfile();
                  
                  // Force rebuild to show new config
                  setState(() {
                    _selectedDashboard = null; // Clear selection to force re-parse
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dashboard config reloaded'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              if (dashboard.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.green.shade600, size: 8),
                      const SizedBox(width: 6),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Widgets grid - wrapped in Consumer for real-time updates
        Expanded(
          child: Consumer<BlynkServiceSimple>(
            builder: (context, blynkService, child) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: dashboard.widgets.length,
                itemBuilder: (context, index) {
                  final widget = dashboard.widgets[index];
                  
                  // Get real-time value from BlynkService based on widget's pin
                  String value = 'N/A';
                  if (widget.dataStream != null) {
                    final pinType = widget.dataStream!.pinType ?? 'VIRTUAL';
                    final pin = widget.dataStream!.pin;
                    final realTimeValue = blynkService.getPinValue(pin, pinType: pinType);
                    
                    if (realTimeValue != null) {
                      value = realTimeValue;
                    } else if (widget.value != null) {
                      // Fallback to stored value from profile
                      value = widget.value!;
                    }
                  } else if (widget.value != null) {
                    // Widget has no pin, use stored value
                    value = widget.value!;
                  }

                  return _buildWidgetCard(widget, value, blynkService);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetCard(WidgetModel widget, String value, BlynkServiceSimple blynk) {
    IconData icon;
    Color color;

    // Choose icon and color based on widget type
    switch (widget.type.toUpperCase()) {
      case 'DIGIT4_DISPLAY':
      case 'LABELED_VALUE_DISPLAY':
        icon = Icons.monitor;
        color = Colors.blue;
        break;
      case 'GAUGE':
        icon = Icons.speed;
        color = Colors.orange;
        break;
      case 'BUTTON':
        icon = Icons.radio_button_checked;
        color = Colors.green;
        break;
      case 'SLIDER':
        icon = Icons.tune;
        color = Colors.purple;
        break;
      case 'LED':
        icon = Icons.lightbulb;
        color = Colors.amber;
        break;
      case 'GRAPH':
      case 'ENHANCED_GRAPH':
        icon = Icons.show_chart;
        color = Colors.teal;
        break;
      default:
        icon = Icons.widgets;
        color = Colors.grey;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Show widget details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.label ?? 'Widget',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.type,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pin: ${widget.dataStream?.pin ?? "N/A"}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              // Value display with controls for writable widgets
              _buildValueControl(widget, value, color, blynk),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildValueControl(WidgetModel widget, String value, Color color, BlynkServiceSimple blynk) {
    final isWritable = widget.type.toUpperCase() == 'BUTTON' || 
                       widget.type.toUpperCase() == 'SLIDER';
    
    if (!isWritable || widget.dataStream == null) {
      // Read-only widget - just show value
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
    }
    
    // Writable widgets - add controls
    final pin = widget.dataStream!.pin;
    final pinType = widget.dataStream!.pinType ?? 'VIRTUAL';
    
    if (widget.type.toUpperCase() == 'BUTTON') {
      // Toggle button
      final isOn = value == '1';
      return ElevatedButton.icon(
        onPressed: () async {
          final newValue = isOn ? '0' : '1';
          if (pinType.toUpperCase() == 'DIGITAL') {
            await blynk.sendDigitalPin(pin, isOn ? 0 : 1);
          } else {
            await blynk.sendVirtualPin(pin, newValue);
          }
        },
        icon: Icon(isOn ? Icons.toggle_on : Icons.toggle_off),
        label: Text(isOn ? 'ON' : 'OFF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOn ? Colors.green : Colors.grey,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
        ),
      );
    } else {
      // Slider
      final min = widget.dataStream!.min ?? 0;
      final max = widget.dataStream!.max ?? 1023;
      final currentValue = double.tryParse(value) ?? min;
      
      return Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Slider(
            value: currentValue.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) > 100) ? 100 : (max - min).toInt(),
            label: value,
            onChanged: (newValue) async {
              final intValue = newValue.round().toString();
              await blynk.sendVirtualPin(pin, intValue);
            },
          ),
        ],
      );
    }
  }
}
