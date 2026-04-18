import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class StorageService {
  static const String annotationsBoxName = 'ghost_annotations';
  static const String buddyRoomsBoxName = 'buddy_rooms';
  static const String progressBoxName = 'reading_progress';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters Manually
    Hive.registerAdapter(GhostAnnotationAdapter());
    Hive.registerAdapter(BuddyRoomAdapter());
    Hive.registerAdapter(ReadingProgressAdapter());

    // Open boxes
    await Hive.openBox<GhostAnnotation>(annotationsBoxName);
    await Hive.openBox<BuddyRoom>(buddyRoomsBoxName);
    await Hive.openBox<ReadingProgress>(progressBoxName);
  }

  static Box<GhostAnnotation> get annotationsBox => Hive.box<GhostAnnotation>(annotationsBoxName);
  static Box<BuddyRoom> get buddyRoomsBox => Hive.box<BuddyRoom>(buddyRoomsBoxName);
  static Box<ReadingProgress> get progressBox => Hive.box<ReadingProgress>(progressBoxName);
}
