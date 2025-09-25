import 'package:hive/hive.dart';

@HiveType(typeId: 10)
class Nota extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String customerName;
  @HiveField(2)
  String deviceType;
  @HiveField(3)
  DateTime date;
  @HiveField(4)
  String invoiceNo;
  @HiveField(5)
  List<NotaItem> items;
  @HiveField(6)
  double tax;
  @HiveField(7)
  String footer;
  @HiveField(8)
  DateTime createdAt;

  Nota({
    required this.id,
    required this.customerName,
    required this.deviceType,
    required this.date,
    required this.invoiceNo,
    required this.items,
    this.tax = 0,
    this.footer = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0, (p, e) => p + e.totalPrice);
  double get total => subtotal + tax;
}

@HiveType(typeId: 11)
class NotaItem extends HiveObject {
  @HiveField(0)
  String description;
  @HiveField(1)
  double barang;
  @HiveField(2)
  double service;

  NotaItem({required this.description, this.barang = 0, this.service = 0});

  double get totalPrice => barang + service;
}

class NotaAdapter extends TypeAdapter<Nota> {
  @override
  final int typeId = 10;

  @override
  Nota read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Nota(
      id: fields[0] as String,
      customerName: fields[1] as String,
      deviceType: fields[2] as String,
      date: fields[3] as DateTime,
      invoiceNo: fields[4] as String,
      items: (fields[5] as List).cast<NotaItem>(),
      tax: (fields[6] as double?) ?? 0,
      footer: (fields[7] as String?) ?? '',
      createdAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Nota obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerName)
      ..writeByte(2)
      ..write(obj.deviceType)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.invoiceNo)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.tax)
      ..writeByte(7)
      ..write(obj.footer)
      ..writeByte(8)
      ..write(obj.createdAt);
  }
}

class NotaItemAdapter extends TypeAdapter<NotaItem> {
  @override
  final int typeId = 11;

  @override
  NotaItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotaItem(
      description: fields[0] as String,
      barang: (fields[1] as double?) ?? 0,
      service: (fields[2] as double?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, NotaItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.description)
      ..writeByte(1)
      ..write(obj.barang)
      ..writeByte(2)
      ..write(obj.service);
  }
}
