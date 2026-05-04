class Couple {
  const Couple({
    required this.id,
    required this.memberIds,
    required this.inviteCode,
    required this.createdAt,
    this.partnerDisplayName,
    this.relationshipStartDate,
  });

  final String id;
  final List<String> memberIds;
  final String inviteCode;
  final String? partnerDisplayName;
  final DateTime? relationshipStartDate;
  final DateTime createdAt;
}
