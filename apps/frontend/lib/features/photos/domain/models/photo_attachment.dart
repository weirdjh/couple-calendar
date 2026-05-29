class PhotoAttachment {
  const PhotoAttachment({
    required this.id,
    required this.label,
    this.storagePath,
    this.downloadUrl,
    this.createdAt,
  });

  final String id;
  final String label;
  final String? storagePath;
  final String? downloadUrl;
  final DateTime? createdAt;

  String get previewLabel => downloadUrl ?? label;
}

List<PhotoAttachment> photoAttachmentsFromLabels(List<String> labels) {
  return List.unmodifiable(
    labels.indexed.map((entry) {
      final label = entry.$2.trim();
      if (label.isEmpty) {
        return null;
      }
      return PhotoAttachment(id: 'photo-${entry.$1 + 1}', label: label);
    }).whereType<PhotoAttachment>(),
  );
}

List<String> photoLabelsFromAttachments(List<PhotoAttachment> photos) {
  return List.unmodifiable(
    photos
        .map((photo) => photo.label.trim())
        .where((label) => label.isNotEmpty),
  );
}
