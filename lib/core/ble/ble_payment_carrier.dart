
import 'dart:async';
import 'dart:convert';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';

class BlePaymentCarrier {
  static final BlePaymentCarrier _instance =
      BlePaymentCarrier._internal();

  factory BlePaymentCarrier() => _instance;

  BlePaymentCarrier._internal();

  final CentralManager _centralManager = CentralManager();
  final PeripheralManager _peripheralManager = PeripheralManager();

  StreamSubscription<BluetoothLowEnergyStateChangedEventArgs>?
      _peripheralStateSubscription;

  StreamSubscription<GATTCharacteristicReadRequestedEventArgs>?
      _readRequestSubscription;

  StreamSubscription<GATTCharacteristicWriteRequestedEventArgs>?
      _writeRequestSubscription;

  Completer<bool>? _stateCompleter;

  static final UUID serviceUuid = UUID.fromString(
    '7A4B0001-7B5C-4D6E-8F70-123456789001',
  );

  static final UUID paymentCharacteristicUuid = UUID.fromString(
    '7A4B0002-7B5C-4D6E-8F70-123456789001',
  );

  static final UUID acknowledgementCharacteristicUuid = UUID.fromString(
    '7A4B0003-7B5C-4D6E-8F70-123456789001',
  );

  GATTService? _paymentService;
  GATTCharacteristic? _paymentCharacteristic;

  bool _initialized = false;

  final Set<String> _receivedNonces = <String>{};

  final Map<String, List<String>> _chunkBuffers = {};
  final Map<String, int> _chunkTotals = {};

  Future<void> initialize() async {
    try {
      debugPrint('[BLE] initialize() started');

      debugPrint('[BLE] Central state: ${_centralManager.state}');
      debugPrint(
        '[BLE] Peripheral state before setup: '
        '${_peripheralManager.state}',
      );

      // READ REQUEST HANDLER
      _readRequestSubscription ??=
          _peripheralManager.characteristicReadRequested.listen(
        (eventArgs) async {
          debugPrint(
            '[BLE] Characteristic read requested: '
            '${eventArgs.characteristic.uuid}',
          );

          if (eventArgs.characteristic.uuid !=
              paymentCharacteristicUuid) {
            debugPrint(
              '[BLE] Read request was for an unknown characteristic.',
            );
            return;
          }

          final value = Uint8List.fromList(
            'CampusPay BLE OK'.codeUnits,
          );

          try {
            await _peripheralManager.respondReadRequestWithValue(
              eventArgs.request,
              value: value,
            );

            debugPrint(
              '[BLE] Read response sent: CampusPay BLE OK',
            );
          } catch (e, stackTrace) {
            debugPrint(
              '[BLE] Failed to respond to read request: $e',
            );
            debugPrint(
              '[BLE] Read response stack trace: $stackTrace',
            );
          }
        },
      );

      // WRITE REQUEST HANDLER
      _writeRequestSubscription ??=
          _peripheralManager.characteristicWriteRequested.listen(
        (eventArgs) async {
          debugPrint(
            '[BLE] Characteristic write requested: '
            '${eventArgs.characteristic.uuid}',
          );

          if (eventArgs.characteristic.uuid !=
              paymentCharacteristicUuid) {
            debugPrint(
              '[BLE] Write request was for an unknown characteristic.',
            );
            return;
          }

          
          final receivedData = eventArgs.request.value;
          final receivedText = utf8.decode(receivedData);

          debugPrint(
            '[BLE] Received ${receivedData.length} bytes',
          );
          debugPrint('[BLE] Received text: $receivedText');

          try {
            // Acknowledge each individual GATT write.
            await _peripheralManager.respondWriteRequest(
              eventArgs.request,
            );

            debugPrint('[BLE] GATT write acknowledged');

            // Expect: CP1|messageId|chunkIndex|totalChunks|base64Data
            final parts = receivedText.split('|');

            if (parts.length != 5 || parts[0] != 'CP1') {
              debugPrint('[BLE] Invalid chunk frame');
              return;
            }

            final messageId = parts[1];
            final chunkIndex = int.tryParse(parts[2]);
            final totalChunks = int.tryParse(parts[3]);
            final chunkData = parts[4];

            if (messageId.isEmpty ||
                chunkIndex == null ||
                totalChunks == null ||
                totalChunks < 1 ||
                totalChunks > 200 ||
                chunkIndex < 0 ||
                chunkIndex >= totalChunks ||
                chunkData.isEmpty) {
              debugPrint('[BLE] Invalid chunk metadata');
              return;
            }

            // Create a buffer for this message.
            if (!_chunkBuffers.containsKey(messageId)) {
              _chunkBuffers[messageId] =
                  List<String>.filled(totalChunks, '');
              _chunkTotals[messageId] = totalChunks;
            }

            final buffer = _chunkBuffers[messageId]!;

            if (_chunkTotals[messageId] != totalChunks ||
                buffer.length != totalChunks) {
              _chunkBuffers.remove(messageId);
              _chunkTotals.remove(messageId);
              debugPrint('[BLE] Inconsistent chunk count; discarded');
              return;
            }

            // Store this chunk. Ignore duplicate chunks safely.
            if (buffer[chunkIndex].isEmpty) {
              buffer[chunkIndex] = chunkData;
            }

            final receivedCount =
                buffer.where((chunk) => chunk.isNotEmpty).length;

            debugPrint(
              '[BLE] Received chunk ${chunkIndex + 1}/$totalChunks '
              'for message $messageId',
            );

            // Wait until every chunk has arrived.
            if (receivedCount != totalChunks) {
              return;
            }

            // Remove buffered state before processing the full message.
            final completeEncodedPayload = buffer.join();
            _chunkBuffers.remove(messageId);
            _chunkTotals.remove(messageId);

            // Reconstruct the original UTF-8 JSON.
            final completeBytes = base64Decode(completeEncodedPayload);
            final completeText = utf8.decode(completeBytes);

            debugPrint(
              '[BLE] Reassembled complete payload: '
              '${completeBytes.length} bytes',
            );

            // PARSE COMPLETE PAYMENT PAYLOAD
            final decoded = jsonDecode(completeText);

            if (decoded is! Map) {
              throw const FormatException(
                'Payment payload is not a JSON object.',
              );
            }

            final Map<String, dynamic> paymentData =
                Map<String, dynamic>.from(decoded);



            // EXTRACT REQUIRED FIELDS
            final tokenId = paymentData['token_id']?.toString();
            final walletId = paymentData['wallet_id']?.toString();
            final serverSignature =
                paymentData['server_signature']?.toString();
            final paymentSignature =
                paymentData['payment_signature']?.toString();
            final nonce = paymentData['nonce']?.toString();
            final merchantId = paymentData['merchant_id']?.toString();
            final merchantName =
                paymentData['merchant_name']?.toString();

            final amountValue = paymentData['amount'];
            final maxAmountValue = paymentData['max_amount'];
            final expiryValue = paymentData['expiry_timestamp'];
            final timestampValue = paymentData['timestamp'];

            if (tokenId == null ||
                tokenId.isEmpty ||
                walletId == null ||
                walletId.isEmpty ||
                serverSignature == null ||
                serverSignature.isEmpty ||
                paymentSignature == null ||
                paymentSignature.isEmpty ||
                nonce == null ||
                nonce.isEmpty ||
                merchantId == null ||
                merchantId.isEmpty ||
                merchantName == null ||
                merchantName.isEmpty ||
                amountValue == null ||
                maxAmountValue == null ||
                expiryValue == null ||
                timestampValue == null) {
              debugPrint(
                '[BLE] Payment rejected: missing required fields.',
              );
              return;
            }

            final amount = (amountValue as num).toDouble();
            final maxAmount = (maxAmountValue as num).toDouble();

            // CHANGED SECTION: normalize timestamps to milliseconds.
            int toMilliseconds(dynamic value) {
              final timestamp = (value as num).toInt();

              return timestamp < 1000000000000
                  ? timestamp * 1000
                  : timestamp;
            }

            final expiryTimestamp = toMilliseconds(expiryValue);
            final timestamp = toMilliseconds(timestampValue);

            // AMOUNT VALIDATION
            if (amount <= 0) {
              debugPrint(
                '[BLE] Payment rejected: invalid amount $amount',
              );
              return;
            }

            if (amount > maxAmount) {
              debugPrint(
                '[BLE] Payment rejected: amount '
                '₹$amount exceeds token limit ₹$maxAmount',
              );
              return;
            }

            // TOKEN EXPIRY VALIDATION
            final now = DateTime.now().millisecondsSinceEpoch;

            if (now > expiryTimestamp) {
              debugPrint(
                '[BLE] Payment rejected: offline token expired.',
              );
              debugPrint('[BLE] Token ID: $tokenId');
              return;
            }

            // TIMESTAMP VALIDATION
            const allowedClockDifference = 5 * 60 * 1000;

            final timestampDifference = (now - timestamp).abs();

            if (timestampDifference > allowedClockDifference) {
              debugPrint(
                '[BLE] Payment rejected: timestamp outside '
                'allowed 5-minute window.',
              );
              debugPrint('[BLE] Current time: $now');
              debugPrint('[BLE] Payment timestamp: $timestamp');
              return;
            }

            // NONCE REPLAY PROTECTION
            if (_receivedNonces.contains(nonce)) {
              debugPrint(
                '[BLE] Payment rejected: nonce already received.',
              );
              debugPrint('[BLE] Replay nonce: $nonce');
              return;
            }

            // PAYMENT ACCEPTED
            // ECDSA signature verification is not performed here.
            _receivedNonces.add(nonce);

            debugPrint('[BLE] P2P_RECEIVE payment accepted.');
            debugPrint('[BLE] Token ID: $tokenId');
            debugPrint('[BLE] Wallet ID: $walletId');
            debugPrint('[BLE] Merchant: $merchantName');
            debugPrint('[BLE] Merchant ID: $merchantId');
            debugPrint('[BLE] Amount: ₹$amount');
            debugPrint('[BLE] Nonce: $nonce');

            // SEND BLE ACK
                      // SEND BLE ACK
            final acknowledgementData = <String, dynamic>{
              'receiver_status': 'accepted',
              'token_id': tokenId,
              'nonce': nonce,
            };

            final acknowledgementPayload =
                jsonEncode(acknowledgementData);

            final acknowledgement = Uint8List.fromList(
              'ACK|$acknowledgementPayload'.codeUnits,
            );

            if (_paymentCharacteristic != null) {
              try {
                await _peripheralManager.notifyCharacteristic(
                  eventArgs.central,
                  _paymentCharacteristic!,
                  value: acknowledgement,
                );

                debugPrint(
                  '[BLE] ACK notification sent successfully.',
                );
                debugPrint('[BLE] ACK status: accepted');
                debugPrint('[BLE] ACK token ID: $tokenId');
                debugPrint('[BLE] ACK nonce: $nonce');
              } catch (e, stackTrace) {
                debugPrint(
                  '[BLE] Failed to send ACK notification: $e',
                );
                debugPrint(
                  '[BLE] ACK notification stack trace: $stackTrace',
                );
              }
            } else {
              debugPrint(
                '[BLE] Cannot send ACK: payment characteristic '
                'is not available.',
              );
            }
          } catch (e, stackTrace) {
            debugPrint('[BLE] Failed to process payment write: $e');
            debugPrint(
              '[BLE] Payment processing stack trace: $stackTrace',
            );
          }
        },
      );

      // PERIPHERAL STATE
      _stateCompleter = Completer<bool>();

      _peripheralStateSubscription ??=
          _peripheralManager.stateChanged.listen(
        (eventArgs) {
          debugPrint(
            '[BLE] Peripheral state changed: ${eventArgs.state}',
          );

          if (eventArgs.state ==
              BluetoothLowEnergyState.poweredOn) {
            debugPrint('[BLE] Peripheral is now poweredOn.');

            if (_stateCompleter != null &&
                !_stateCompleter!.isCompleted) {
              _stateCompleter!.complete(true);
            }
          } else if (eventArgs.state ==
                  BluetoothLowEnergyState.poweredOff ||
              eventArgs.state ==
                  BluetoothLowEnergyState.unauthorized ||
              eventArgs.state ==
                  BluetoothLowEnergyState.unsupported) {
            if (_stateCompleter != null &&
                !_stateCompleter!.isCompleted) {
              _stateCompleter!.complete(false);
            }
          }
        },
      );

      if (_peripheralManager.state ==
          BluetoothLowEnergyState.poweredOn) {
        debugPrint('[BLE] Peripheral is already poweredOn.');

        if (!_stateCompleter!.isCompleted) {
          _stateCompleter!.complete(true);
        }
      } else {
        debugPrint(
          '[BLE] Waiting for peripheral manager to become poweredOn...',
        );
      }

      final ready = await _stateCompleter!.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
            '[BLE] Timed out waiting for peripheral poweredOn.',
          );
          return false;
        },
      );

      _stateCompleter = null;

      debugPrint('[BLE] Peripheral wait result: $ready');

      if (!ready) {
        debugPrint(
          '[BLE] Peripheral manager did not become poweredOn. '
          'GATT setup cancelled.',
        );
        return;
      }

      if (_initialized) {
        debugPrint('[BLE] Already initialized');
        return;
      }

      // GATT SERVICE
      debugPrint(
        '[BLE] Peripheral manager is poweredOn. '
        'Creating GATT service...',
      );

      final paymentCharacteristic = GATTCharacteristic.mutable(
        uuid: paymentCharacteristicUuid,
        properties: [
          GATTCharacteristicProperty.read,
          GATTCharacteristicProperty.write,
          GATTCharacteristicProperty.notify,
        ],
        permissions: [
          GATTCharacteristicPermission.read,
          GATTCharacteristicPermission.write,
        ],
        descriptors: [],
      );

      _paymentCharacteristic = paymentCharacteristic;

      _paymentService = GATTService(
        uuid: serviceUuid,
        isPrimary: true,
        includedServices: [],
        characteristics: [paymentCharacteristic],
      );

      debugPrint('[BLE] Adding GATT service...');

      await _peripheralManager.addService(_paymentService!);

      debugPrint('[BLE] GATT service added successfully');

      // ADVERTISING
      debugPrint('[BLE] Starting BLE advertising...');

      await _peripheralManager.startAdvertising(
        Advertisement(
          serviceUUIDs: [serviceUuid],
        ),
      );

      _initialized = true;

      debugPrint('[BLE] Advertising started successfully');
      debugPrint('[BLE] CampusPay payment service ready');
    } catch (e, stackTrace) {
      debugPrint('[BLE] Initialization error: $e');
      debugPrint('[BLE] Stack trace: $stackTrace');

      _stateCompleter = null;
    }
  }

  void dispose() {
    _peripheralStateSubscription?.cancel();
    _peripheralStateSubscription = null;

    _readRequestSubscription?.cancel();
    _readRequestSubscription = null;

    _writeRequestSubscription?.cancel();
    _writeRequestSubscription = null;

    _stateCompleter = null;

    _receivedNonces.clear();
  }
}
