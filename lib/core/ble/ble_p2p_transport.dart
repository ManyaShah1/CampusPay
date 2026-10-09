import 'dart:async';
import 'dart:convert';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';

class BleP2pTransport {
  static final BleP2pTransport _instance =
      BleP2pTransport._internal();

  factory BleP2pTransport() => _instance;

  BleP2pTransport._internal();

  final CentralManager _centralManager = CentralManager();

  StreamSubscription<DiscoveredEventArgs>? _discoveredSubscription;

  StreamSubscription<GATTCharacteristicNotifiedEventArgs>?
      _notificationSubscription;

  Peripheral? _connectedPeripheral;

  Completer<Peripheral?>? _discoveryCompleter;

  Completer<String>? _ackCompleter;

  static final UUID serviceUuid = UUID.fromString(
    '7A4B0001-7B5C-4D6E-8F70-123456789001',
  );

  static final UUID paymentCharacteristicUuid = UUID.fromString(
    '7A4B0002-7B5C-4D6E-8F70-123456789001',
  );

  Future<bool> sendPayment({
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      debugPrint('[BLE-P2P] Starting payment transfer');

      await _ensureCentralReady();

      final peripheral = await _findCampusPayDevice();

      if (peripheral == null) {
        debugPrint(
          '[BLE-P2P] CampusPay receiver not found',
        );
        return false;
      }

      debugPrint(
        '[BLE-P2P] CampusPay receiver discovered',
      );

      debugPrint(
        '[BLE-P2P] Connecting to receiver...',
      );

      await _centralManager.connect(peripheral);

      _connectedPeripheral = peripheral;

      debugPrint(
        '[BLE-P2P] Connected to CampusPay receiver',
      );

      final services =
          await _centralManager.discoverGATT(peripheral);

      GATTCharacteristic? paymentCharacteristic;

      for (final service in services) {
        if (service.uuid != serviceUuid) {
          continue;
        }

        for (final characteristic
            in service.characteristics) {
          if (characteristic.uuid ==
              paymentCharacteristicUuid) {
            paymentCharacteristic = characteristic;
            break;
          }
        }

        if (paymentCharacteristic != null) {
          break;
        }
      }

      if (paymentCharacteristic == null) {
        debugPrint(
          '[BLE-P2P] Payment characteristic not found',
        );

        await _disconnect();

        return false;
      }

      debugPrint(
        '[BLE-P2P] Payment characteristic discovered',
      );

      _ackCompleter = Completer<String>();

      await _notificationSubscription?.cancel();

      _notificationSubscription =
          _centralManager.characteristicNotified.listen(
        (eventArgs) {
          if (eventArgs.characteristic.uuid !=
              paymentCharacteristicUuid) {
            return;
          }

          final receivedText =
              String.fromCharCodes(eventArgs.value);

          debugPrint(
            '[BLE-P2P] Notification received: '
            '$receivedText',
          );

          if (_ackCompleter != null &&
              !_ackCompleter!.isCompleted) {
            _ackCompleter!.complete(receivedText);
          }
        },
      );

      debugPrint(
        '[BLE-P2P] Enabling notifications...',
      );

      await _centralManager.setCharacteristicNotifyState(
        peripheral,
        paymentCharacteristic,
        state: true,
      );

      final payloadJson = jsonEncode(paymentData);

      final payloadBytes =
          Uint8List.fromList(payloadJson.codeUnits);

      debugPrint(
        '[BLE-P2P] Sending payment payload:',
      );

      debugPrint(
        '[BLE-P2P] $payloadJson',
      );

      await _centralManager.writeCharacteristic(
        peripheral,
        paymentCharacteristic,
        value: payloadBytes,
        type: GATTCharacteristicWriteType.withResponse,
      );

      debugPrint(
        '[BLE-P2P] Payment payload written successfully',
      );

      final acknowledgement =
          await _ackCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException(
            'No BLE payment ACK received within 5 seconds',
          );
        },
      );

      debugPrint(
        '[BLE-P2P] ACK received: $acknowledgement',
      );

      final nonce = paymentData['nonce']?.toString();

      final tokenId =
          paymentData['token_id']?.toString();

      if (nonce == null || tokenId == null) {
        debugPrint(
          '[BLE-P2P] Payment is missing nonce or token ID',
        );

        await _disconnect();

        return false;
      }

      const expectedPrefix = 'ACK|';

      if (!acknowledgement.startsWith(
        expectedPrefix,
      )) {
        debugPrint(
          '[BLE-P2P] Invalid ACK prefix',
        );

        await _disconnect();

        return false;
      }

      final acknowledgedPayload =
          acknowledgement.substring(
        expectedPrefix.length,
      );

      Map<String, dynamic> acknowledgedData;

      try {
        acknowledgedData =
            jsonDecode(acknowledgedPayload)
                as Map<String, dynamic>;
      } catch (e) {
        debugPrint(
          '[BLE-P2P] Could not decode ACK payload: $e',
        );

        await _disconnect();

        return false;
      }

      final acknowledgedNonce =
          acknowledgedData['nonce']?.toString();

      final acknowledgedTokenId =
          acknowledgedData['token_id']?.toString();

      if (acknowledgedNonce != nonce ||
          acknowledgedTokenId != tokenId) {
        debugPrint(
          '[BLE-P2P] ACK does not match payment',
        );

        debugPrint(
          '[BLE-P2P] Expected token: $tokenId',
        );

        debugPrint(
          '[BLE-P2P] Received token: '
          '$acknowledgedTokenId',
        );

        debugPrint(
          '[BLE-P2P] Expected nonce: $nonce',
        );

        debugPrint(
          '[BLE-P2P] Received nonce: '
          '$acknowledgedNonce',
        );

        await _disconnect();

        return false;
      }

      debugPrint(
        '[BLE-P2P] Payment ACK verified successfully',
      );

      await _disconnect();

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        '[BLE-P2P] Payment transfer failed: $e',
      );

      debugPrint(
        '[BLE-P2P] Stack trace: $stackTrace',
      );

      await _disconnect();

      return false;
    } finally {
      _ackCompleter = null;
    }
  }

  Future<void> _ensureCentralReady() async {
    if (_centralManager.state ==
        BluetoothLowEnergyState.poweredOn) {
      return;
    }

    final completer = Completer<void>();

    late StreamSubscription<
        BluetoothLowEnergyStateChangedEventArgs> subscription;

    subscription =
        _centralManager.stateChanged.listen((eventArgs) {
      debugPrint(
        '[BLE-P2P] Central state: ${eventArgs.state}',
      );

      if (eventArgs.state ==
          BluetoothLowEnergyState.poweredOn) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }

      if (eventArgs.state ==
              BluetoothLowEnergyState.poweredOff ||
          eventArgs.state ==
              BluetoothLowEnergyState.unauthorized ||
          eventArgs.state ==
              BluetoothLowEnergyState.unsupported) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception(
              'BLE central unavailable: '
              '${eventArgs.state}',
            ),
          );
        }
      }
    });

    try {
      await completer.future.timeout(
        const Duration(seconds: 10),
      );
    } finally {
      await subscription.cancel();
    }
  }

  Future<Peripheral?> _findCampusPayDevice() async {
    _discoveryCompleter =
        Completer<Peripheral?>();

    await _discoveredSubscription?.cancel();

    _discoveredSubscription =
        _centralManager.discovered.listen(
      (eventArgs) {
        debugPrint(
          '[BLE-P2P] Discovered BLE peripheral',
        );

        if (!_discoveryCompleter!.isCompleted) {
          _discoveryCompleter!.complete(
            eventArgs.peripheral,
          );
        }
      },
    );

    debugPrint(
      '[BLE-P2P] Starting CampusPay service discovery...',
    );

    await _centralManager.startDiscovery(
      serviceUUIDs: [serviceUuid],
    );

    try {
      return await _discoveryCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } finally {
      await _centralManager.stopDiscovery();

      await _discoveredSubscription?.cancel();

      _discoveredSubscription = null;

      _discoveryCompleter = null;
    }
  }

  Future<void> _disconnect() async {
    final peripheral = _connectedPeripheral;

    if (peripheral == null) {
      return;
    }

    try {
      await _centralManager.disconnect(
        peripheral,
      );
    } catch (e) {
      debugPrint(
        '[BLE-P2P] Disconnect error: $e',
      );
    }

    _connectedPeripheral = null;
  }

  Future<void> dispose() async {
    await _discoveredSubscription?.cancel();

    await _notificationSubscription?.cancel();

    _discoveredSubscription = null;

    _notificationSubscription = null;

    await _disconnect();
  }
}