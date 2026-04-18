import 'package:hive/hive.dart';

class GhostAnnotation extends HiveObject {
  String id;
  String bookId;
  int pageNumber;
  String encryptedPayload;
  int timestamp;

  GhostAnnotation({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    required this.encryptedPayload,
    required this.timestamp,
  });
}

class GhostAnnotationAdapter extends TypeAdapter<GhostAnnotation> {
  @override
  final int typeId = 0;

  @override
  GhostAnnotation read(BinaryReader reader) {
    return GhostAnnotation(
      id: reader.read(),
      bookId: reader.read(),
      pageNumber: reader.read(),
      encryptedPayload: reader.read(),
      timestamp: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, GhostAnnotation obj) {
    writer.write(obj.id);
    writer.write(obj.bookId);
    writer.write(obj.pageNumber);
    writer.write(obj.encryptedPayload);
    writer.write(obj.timestamp);
  }
}

class BuddyRoom extends HiveObject {
  String roomId;
  String secret;

  BuddyRoom({
    required this.roomId,
    required this.secret,
  });
}

class BuddyRoomAdapter extends TypeAdapter<BuddyRoom> {
  @override
  final int typeId = 1;

  @override
  BuddyRoom read(BinaryReader reader) {
    return BuddyRoom(
      roomId: reader.read(),
      secret: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, BuddyRoom obj) {
    writer.write(obj.roomId);
    writer.write(obj.secret);
  }
}

class ReadingProgress extends HiveObject {
  String bookId;
  int currentPage;

  ReadingProgress({
    required this.bookId,
    required this.currentPage,
  });
}

class ReadingProgressAdapter extends TypeAdapter<ReadingProgress> {
  @override
  final int typeId = 2;

  @override
  ReadingProgress read(BinaryReader reader) {
    return ReadingProgress(
      bookId: reader.read(),
      currentPage: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, ReadingProgress obj) {
    writer.write(obj.bookId);
    writer.write(obj.currentPage);
  }
}
