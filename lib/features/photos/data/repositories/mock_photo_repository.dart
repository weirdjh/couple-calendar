import '../../domain/models/photo_attachment.dart';
import 'photo_repository.dart';

class MockPhotoRepository implements PhotoRepository {
  var _nextId = 1;

  @override
  Future<PhotoAttachment> createPlaceholderPhoto({
    required String coupleId,
    required String ownerPath,
    required String uploadedBy,
    required String label,
  }) async {
    final trimmedLabel = label.trim();
    return PhotoAttachment(
      id: 'photo-${_nextId++}',
      label: trimmedLabel.isEmpty ? '사진' : trimmedLabel,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deletePhoto({
    required String coupleId,
    required String ownerPath,
    required String photoId,
  }) async {}
}
