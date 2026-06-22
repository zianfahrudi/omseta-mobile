import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_exception.dart';

/// Thin wrapper around print_bluetooth_thermal: list paired printers, connect,
/// send bytes, and remember the last-used printer.
class ThermalPrinterService {
  static const _kLastPrinter = 'last_printer_mac';

  /// Bluetooth on + permission granted. Throws [ApiException] with a friendly
  /// message otherwise.
  Future<void> ensureReady() async {
    final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!granted) {
      throw ApiException('Izin Bluetooth ditolak. Aktifkan dari pengaturan.');
    }
    final enabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!enabled) {
      throw ApiException('Bluetooth tidak aktif. Nyalakan Bluetooth dulu.');
    }
  }

  Future<List<BluetoothInfo>> pairedPrinters() async {
    return PrintBluetoothThermal.pairedBluetooths;
  }

  Future<String?> lastPrinterMac() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastPrinter);
  }

  Future<void> _rememberPrinter(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastPrinter, mac);
  }

  /// Connects to [mac] (if not already), sends [bytes], and remembers it.
  Future<void> printBytes({
    required String mac,
    required List<int> bytes,
  }) async {
    final connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) {
      final ok = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (!ok) {
        throw ApiException('Gagal terhubung ke printer. Coba lagi.');
      }
    }
    final wrote = await PrintBluetoothThermal.writeBytes(bytes);
    if (!wrote) {
      throw ApiException('Gagal mengirim data ke printer.');
    }
    await _rememberPrinter(mac);
  }
}
