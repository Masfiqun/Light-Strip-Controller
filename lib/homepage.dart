import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  BluetoothConnection? _connection;
  bool _connecting = false;
  bool _connected = false;

  int _r = 0, _g = 0, _b = 0;

  final Map<String, List<int>> presets = {
    '🌅 Sunset': [255, 80, 30],
    '❄ Cool White': [180, 180, 255],
    '🎉 Party': [255, 0, 255],
    '🛋 Relax': [100, 30, 10],
    '🌊 Ocean': [20, 120, 200],
  };

  @override
  void initState() {
    super.initState();
    _getBondedDevices();
  }

  Future<void> _getBondedDevices() async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      setState(() => _devices = devices);
    } catch (_) {}
  }

  Future<void> _connect() async {
    if (_selectedDevice == null) return;
    setState(() => _connecting = true);
    try {
      _connection = await BluetoothConnection.toAddress(_selectedDevice!.address);
      _connected = true;
      _connection!.input?.listen((data) {
        // Handle data if needed
      }).onDone(() => _disconnect());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
    setState(() => _connecting = false);
  }

  void _disconnect() {
    _connection?.dispose();
    _connection = null;
    setState(() => _connected = false);
  }

  String _buildCmd() => 'S,R,$_r,G,$_g,B,$_b\n';

  void _sendCurrentColor() {
    if (!_connected || _connection == null) return;
    try {
      _connection!.output.add(utf8.encode(_buildCmd()));
    } catch (_) {}
  }

  void _setPreset(List<int> rgb) {
    setState(() {
      _r = rgb[0];
      _g = rgb[1];
      _b = rgb[2];
    });
    _sendCurrentColor();
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white)),
          SizedBox(height: 12),
          child
        ],
      ),
    );
  }

  Widget _buildConnectionCard() {
    return _card(
      title: "Bluetooth Connection",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<BluetoothDevice>(
                  dropdownColor: Colors.black87,
                  isExpanded: true,
                  hint: Text('Select device', style: TextStyle(color: Colors.white)),
                  value: _selectedDevice,
                  items: _devices
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              '${d.name ?? "Unknown"} (${d.address})',
                              style: TextStyle(color: Colors.white),
                            ),
                          ))
                      .toList(),
                  onChanged: (d) => setState(() => _selectedDevice = d),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _connected ? Colors.redAccent : Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: _connecting
                    ? null
                    : _connected
                        ? _disconnect
                        : _connect,
                child: Text(_connecting
                    ? 'Connecting...'
                    : _connected
                        ? 'Disconnect'
                        : 'Connect'),
              )
            ],
          ),
          SizedBox(height: 8),
          Text('Status: ${_connected ? '✅ Connected' : '❌ Not connected'}',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildPresetsCard() {
    return _card(
      title: "Presets",
      child: Wrap(
        spacing: 8,
        children: presets.entries
            .map((e) => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () => _setPreset(e.value),
                  child: Text(e.key, style: TextStyle(color: Colors.white),),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildManualControlCard() {
    return _card(
      title: "Manual Control",
      child: Column(
        children: [
          _rgbSlider("R", _r, Colors.red, (v) => setState(() => _r = v)),
          _rgbSlider("G", _g, Colors.green, (v) => setState(() => _g = v)),
          _rgbSlider("B", _b, Colors.blue, (v) => setState(() => _b = v)),
          SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: _sendCurrentColor,
                child: Text('Send'),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  setState(() => _r = _g = _b = 0);
                  _sendCurrentColor();
                },
                child: Text('All Off'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _rgbSlider(String label, int value, Color color, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Colors.white)),
        Expanded(
          child: Slider(
            activeColor: color,
            min: 0,
            max: 255,
            divisions: 255,
            value: value.toDouble(),
            onChanged: (v) => onChanged(v.round()),
            onChangeEnd: (_) => _sendCurrentColor(),
          ),
        ),
        Text('$value', style: TextStyle(color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ✅ no gradient here
      appBar: AppBar(
        centerTitle: true,
        title: Text('🎨 LightStrip Controller', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _getBondedDevices,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildConnectionCard(),
              _buildPresetsCard(),
              _buildManualControlCard(),
              SizedBox(height: 20),
              Text(
                '💡 Pull down to refresh paired devices.',
                style: TextStyle(color: Colors.white54),
              )
            ],
          ),
        ),
      ),
    );
  }
}
