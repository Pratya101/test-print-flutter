import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothPrinterPage(),
    );
  }
}

class BluetoothPrinterPage extends StatefulWidget {
  @override
  _BluetoothPrinterPageState createState() => _BluetoothPrinterPageState();
}

class _BluetoothPrinterPageState extends State<BluetoothPrinterPage> {
  BluetoothPrint _bluetoothPrint = BluetoothPrint.instance;
  bool _isConnected = false;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await requestBluetoothPermissions();

    _bluetoothPrint.startScan(timeout: Duration(seconds: 4));

    _bluetoothPrint.scanResults.listen((devices) {
      setState(() {
        _devices = devices;
      });
    });

    _bluetoothPrint.state.listen((state) {
      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _isConnected = true;
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _isConnected = false;
          });
          break;
        default:
          break;
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _selectedDevice = device;
    await _bluetoothPrint.connect(device);
  }

  void _printTest() async {
    if (_isConnected && _selectedDevice != null) {
      Map<String, dynamic> config = {};
      List<LineText> list = [];

      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Test Print',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));

      await _bluetoothPrint.printReceipt(config, list);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Printer'),
      ),
      body: Column(
        children: [
          _isConnected
              ? Text('Connected to ${_selectedDevice?.name}')
              : Text('Disconnected'),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_devices[index].name ?? ''),
                  subtitle: Text(_devices[index].address ?? ''),
                  onTap: () => _connectToDevice(_devices[index]),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _isConnected ? _printTest : null,
            child: Text('Print Test'),
          ),
        ],
      ),
    );
  }
}

Future<void> requestBluetoothPermissions() async {
  await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location
  ].request();
}
