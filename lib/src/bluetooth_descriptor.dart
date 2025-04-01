// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of flutter_blue;

/// A class representing a Bluetooth GATT descriptor.
/// Descriptors provide additional information about a characteristic's value.
class BluetoothDescriptor {
  static const String _methodReadResponse = 'ReadDescriptorResponse';
  static const String _methodWriteResponse = 'WriteDescriptorResponse';

  /// The Client Characteristic Configuration Descriptor (CCCD) UUID
  static final Guid cccd = Guid('00002902-0000-1000-8000-00805f9b34fb');

  final Guid uuid;
  final DeviceIdentifier deviceId;
  final Guid serviceUuid;
  final Guid characteristicUuid;

  final BehaviorSubject<List<int>> _value;
  Stream<List<int>> get value => _value.stream;
  List<int> get lastValue => _value.value ?? [];

  BluetoothDescriptor.fromProto(protos.BluetoothDescriptor p)
      : uuid = Guid(p.uuid),
        deviceId = DeviceIdentifier(p.remoteId),
        serviceUuid = Guid(p.serviceUuid),
        characteristicUuid = Guid(p.characteristicUuid),
        _value = BehaviorSubject.seeded(p.value);

  bool _matchesRequest(dynamic response, dynamic request) =>
      response.remoteId == request.remoteId &&
      response.descriptorUuid == request.descriptorUuid &&
      response.characteristicUuid == request.characteristicUuid &&
      response.serviceUuid == request.serviceUuid;

  /// Reads the current value of the descriptor.
  ///
  /// Returns a [Future] that completes with the descriptor's value as a [List<int>].
  /// Throws a [BluetoothException] if the read operation fails.
  Future<List<int>> read() async {
    final request = protos.ReadDescriptorRequest.create()
      ..remoteId = deviceId.toString()
      ..descriptorUuid = uuid.toString()
      ..characteristicUuid = characteristicUuid.toString()
      ..serviceUuid = serviceUuid.toString();

    try {
      await FlutterBlue.instance._channel.invokeMethod('readDescriptor', request.writeToBuffer());

      final value = await FlutterBlue.instance._methodStream
          .where((m) => m.method == _methodReadResponse)
          .map((m) => m.arguments)
          .map((buffer) => protos.ReadDescriptorResponse.fromBuffer(buffer))
          .where((p) => _matchesRequest(p.request, request))
          .map((d) => d.value)
          .first;

      _value.add(value);
      return value;
    } catch (e) {
      throw BluetoothException('Failed to read descriptor: $e');
    }
  }

  /// Writes a new value to the descriptor.
  ///
  /// [value] is the new value to write as a [List<int>].
  /// Throws a [BluetoothException] if the write operation fails.
  Future<void> write(List<int> value) async {
    final request = protos.WriteDescriptorRequest.create()
      ..remoteId = deviceId.toString()
      ..descriptorUuid = uuid.toString()
      ..characteristicUuid = characteristicUuid.toString()
      ..serviceUuid = serviceUuid.toString()
      ..value = value;

    try {
      await FlutterBlue.instance._channel.invokeMethod('writeDescriptor', request.writeToBuffer());

      final success = await FlutterBlue.instance._methodStream
          .where((m) => m.method == _methodWriteResponse)
          .map((m) => m.arguments)
          .map((buffer) => protos.WriteDescriptorResponse.fromBuffer(buffer))
          .where((p) => _matchesRequest(p.request, request))
          .first
          .then((w) => w.success);

      if (!success) {
        throw BluetoothException('Failed to write descriptor');
      }

      _value.add(value);
    } catch (e) {
      throw BluetoothException('Write operation failed: $e');
    }
  }

  @override
  String toString() {
    final currentValue = _value.value;
    return 'BluetoothDescriptor{uuid: $uuid, deviceId: $deviceId, '
        'serviceUuid: $serviceUuid, characteristicUuid: $characteristicUuid, '
        'value: ${currentValue ?? 'null'}}';
  }
}
