import '../../domain/models/photo_attachment.dart';

abstract class PhotoRepository {
  Future<PhotoAttachment> createPlaceholderPhoto({
    required String coupleId,
    required String ownerPath,
    required String uploadedBy,
    required String label,
  });

  Future<void> deletePhoto({
    required String coupleId,
    required String ownerPath,
    required String photoId,
  });
}
