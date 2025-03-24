// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of flutter_blue;

class BluetoothCharacteristic {
  final Guid uuid;
  final DeviceIdentifier deviceId;
  final Guid serviceUuid;
  final Guid? secondaryServiceUuid;
  final CharacteristicProperties properties;
  final List<BluetoothDescriptor> descriptors;

  static const String _methodCharacteristicChanged = 'OnCharacteristicChanged';
  static const String _methodReadResponse = 'ReadCharacteristicResponse';
  static const String _methodWriteResponse = 'WriteCharacteristicResponse';
  static const String _methodSetNotification = 'SetNotificationResponse';

  bool get isNotifying {
    try {
      final cccd = descriptors.firstWhere(
        (d) => d.uuid == BluetoothDescriptor.cccd,
        orElse: () => throw StateError('CCCD descriptor not found'),
      );
      final value = cccd.lastValue;
      if (value.isEmpty) return false;
      return (value[0] & 0x03) > 0;
    } catch (e) {
      return false;
    }
  }

  BehaviorSubject<List<int>> _value;
  Stream<List<int>> get value => Rx.merge([_value.stream, _onValueChangedStream]);

  List<int> get lastValue => _value.value ?? [];

  BluetoothCharacteristic.fromProto(protos.BluetoothCharacteristic p)
      : uuid = new Guid(p.uuid),
        deviceId = new DeviceIdentifier(p.remoteId),
        serviceUuid = new Guid(p.serviceUuid),
        secondaryServiceUuid = (p.secondaryServiceUuid.length > 0) ? new Guid(p.secondaryServiceUuid) : null,
        descriptors = p.descriptors.map((d) => new BluetoothDescriptor.fromProto(d)).toList(),
        properties = new CharacteristicProperties.fromProto(p.properties),
        _value = BehaviorSubject.seeded(p.value);

  Stream<BluetoothCharacteristic> get _onCharacteristicChangedStream => FlutterBlue.instance._methodStream
          .where((m) => m.method == _methodCharacteristicChanged)
          .map((m) => m.arguments)
          .map((buffer) => new protos.OnCharacteristicChanged.fromBuffer(buffer))
          .where((p) => p.remoteId == deviceId.toString())
          .map((p) => new BluetoothCharacteristic.fromProto(p.characteristic))
          .where((c) => c.uuid == uuid)
          .map((c) {
        _updateDescriptors(c.descriptors);
        return c;
      });

  Stream<List<int>> get _onValueChangedStream => _onCharacteristicChangedStream.map((c) => c.lastValue);

  void _updateDescriptors(List<BluetoothDescriptor> newDescriptors) {
    final descriptorMap = Map.fromEntries(descriptors.map((d) => MapEntry(d.uuid, d)));

    for (final newD in newDescriptors) {
      descriptorMap[newD.uuid]?._value.add(newD.lastValue);
    }
  }

  Future<List<int>> read() async {
    final request = protos.ReadCharacteristicRequest.create()
      ..remoteId = deviceId.toString()
      ..characteristicUuid = uuid.toString()
      ..serviceUuid = serviceUuid.toString();

    try {
      await FlutterBlue.instance._channel.invokeMethod('readCharacteristic', request.writeToBuffer());

      final response = await FlutterBlue.instance._methodStream
          .where((m) => m.method == _methodReadResponse)
          .map((m) => m.arguments)
          .map((buffer) => protos.ReadCharacteristicResponse.fromBuffer(buffer))
          .where((p) => _matchesRequest(p, request))
          .first;

      final value = response.characteristic.value;
      _value.add(value);
      return value;
    } catch (e) {
      throw BluetoothException('Failed to read characteristic: $e');
    }
  }

  bool _matchesRequest(dynamic response, dynamic request) {
    return (response.remoteId == request.remoteId) &&
        (response.characteristic?.uuid == request.characteristicUuid) &&
        (response.characteristic?.serviceUuid == request.serviceUuid);
  }

  Future<void> write(List<int> value, {bool withoutResponse = false}) async {
    final type = withoutResponse ? CharacteristicWriteType.withoutResponse : CharacteristicWriteType.withResponse;

    final request = protos.WriteCharacteristicRequest.create()
      ..remoteId = deviceId.toString()
      ..characteristicUuid = uuid.toString()
      ..serviceUuid = serviceUuid.toString()
      ..writeType = protos.WriteCharacteristicRequest_WriteType.valueOf(type.index)!
      ..value = value;

    try {
      final result = await FlutterBlue.instance._channel.invokeMethod('writeCharacteristic', request.writeToBuffer());

      if (type == CharacteristicWriteType.withoutResponse) {
        return;
      }

      final success = await FlutterBlue.instance._methodStream
          .where((m) => m.method == _methodWriteResponse)
          .map((m) => m.arguments)
          .map((buffer) => protos.WriteCharacteristicResponse.fromBuffer(buffer))
          .where((p) => _matchesRequest(p.request, request))
          .first
          .then((w) => w.success);

      if (!success) {
        throw BluetoothException('Failed to write characteristic');
      }
    } catch (e) {
      throw BluetoothException('Write operation failed: $e');
    }
  }

  Future<bool> setNotifyValue(bool notify) async {
    var request = protos.SetNotificationRequest.create()
      ..remoteId = deviceId.toString()
      ..serviceUuid = serviceUuid.toString()
      ..characteristicUuid = uuid.toString()
      ..enable = notify;

    await FlutterBlue.instance._channel.invokeMethod('setNotification', request.writeToBuffer());

    return FlutterBlue.instance._methodStream
        .where((m) => m.method == _methodSetNotification)
        .map((m) => m.arguments)
        .map((buffer) => new protos.SetNotificationResponse.fromBuffer(buffer))
        .where(
          (p) =>
              (p.remoteId == request.remoteId) &&
              (p.characteristic.uuid == request.characteristicUuid) &&
              (p.characteristic.serviceUuid == request.serviceUuid),
        )
        .first
        .then((p) => new BluetoothCharacteristic.fromProto(p.characteristic))
        .then((c) {
      _updateDescriptors(c.descriptors);
      return (c.isNotifying == notify);
    });
  }

  @override
  String toString() {
    return 'BluetoothCharacteristic{uuid: $uuid, deviceId: $deviceId, serviceUuid: $serviceUuid, secondaryServiceUuid: $secondaryServiceUuid, properties: $properties, descriptors: $descriptors, value: ${_value.value}';
  }
}

enum CharacteristicWriteType { withResponse, withoutResponse }

@immutable
class CharacteristicProperties {
  final bool broadcast;
  final bool read;
  final bool writeWithoutResponse;
  final bool write;
  final bool notify;
  final bool indicate;
  final bool authenticatedSignedWrites;
  final bool extendedProperties;
  final bool notifyEncryptionRequired;
  final bool indicateEncryptionRequired;

  CharacteristicProperties({
    this.broadcast = false,
    this.read = false,
    this.writeWithoutResponse = false,
    this.write = false,
    this.notify = false,
    this.indicate = false,
    this.authenticatedSignedWrites = false,
    this.extendedProperties = false,
    this.notifyEncryptionRequired = false,
    this.indicateEncryptionRequired = false,
  });

  CharacteristicProperties.fromProto(protos.CharacteristicProperties p)
      : broadcast = p.broadcast,
        read = p.read,
        writeWithoutResponse = p.writeWithoutResponse,
        write = p.write,
        notify = p.notify,
        indicate = p.indicate,
        authenticatedSignedWrites = p.authenticatedSignedWrites,
        extendedProperties = p.extendedProperties,
        notifyEncryptionRequired = p.notifyEncryptionRequired,
        indicateEncryptionRequired = p.indicateEncryptionRequired;

  @override
  String toString() {
    return 'CharacteristicProperties{broadcast: $broadcast, read: $read, writeWithoutResponse: $writeWithoutResponse, write: $write, notify: $notify, indicate: $indicate, authenticatedSignedWrites: $authenticatedSignedWrites, extendedProperties: $extendedProperties, notifyEncryptionRequired: $notifyEncryptionRequired, indicateEncryptionRequired: $indicateEncryptionRequired}';
  }
}

class BluetoothException implements Exception {
  final String message;
  BluetoothException(this.message);

  @override
  String toString() => 'BluetoothException: $message';
}
