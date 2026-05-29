import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../date_records/domain/models/date_record.dart';
import '../../../date_records/presentation/controllers/date_record_controller.dart';
import '../../../date_records/presentation/screens/date_record_screen.dart';
import '../../../links/domain/models/linked_item.dart';
import '../../domain/models/review.dart';
import '../controllers/review_controller.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰'),
        actions: [
          IconButton(
            tooltip: '리뷰 추가',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ReviewEditScreen())),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (state.errorMessage != null) ...[
              _ErrorPanel(message: state.errorMessage!),
              const SizedBox(height: 12),
            ],
            if (state.reviews.isEmpty)
              _EmptyPanel(
                text: '리뷰가 아직 없어요.',
                actionLabel: '첫 리뷰 만들기',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReviewEditScreen()),
                ),
              )
            else ...[
              ...state.reviews.map((review) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReviewCard(
                    review: review,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReviewDetailScreen(review.id),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class ReviewDetailScreen extends ConsumerWidget {
  const ReviewDetailScreen(this.reviewId, {super.key});

  final String? reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = reviewId;
    final review = id == null
        ? null
        : ref.watch(reviewControllerProvider).reviewById(id);
    if (review == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('리뷰를 찾을 수 없어요.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 상세'),
        actions: [
          IconButton(
            tooltip: '편집',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReviewEditScreen(reviewId: review.id),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ReviewHeader(review: review),
            if (review.photoLabels.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ReviewPhotoGallery(photoLabels: review.photoLabels),
            ],
            const SizedBox(height: 12),
            _ReviewSection(
              icon: Icons.notes_outlined,
              title: '감상',
              child: Text(
                review.memo.isEmpty ? '아직 감상을 적지 않았어요.' : review.memo,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 12),
            _ReviewSection(
              icon: Icons.place_outlined,
              title: '데이트',
              child: review.dateRecordId == null
                  ? SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _linkDateRecord(context, ref, review),
                        icon: const Icon(Icons.add_link),
                        label: const Text('연결'),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DateRecordDetailScreen(review.dateRecordId),
                            ),
                          ),
                          icon: const Icon(Icons.place_outlined),
                          label: const Text('보기'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _unlinkDateRecord(context, ref, review),
                          icon: const Icon(Icons.link_off),
                          label: const Text('해제'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _linkDateRecord(
    BuildContext context,
    WidgetRef ref,
    Review review,
  ) async {
    final record = await showModalBottomSheet<DateRecord>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DateRecordPickerSheet(
        records: ref.read(dateRecordControllerProvider).records,
      ),
    );
    if (record == null || !context.mounted) {
      return;
    }
    final linkedReview = await ref
        .read(reviewControllerProvider.notifier)
        .linkDateRecord(reviewId: review.id, dateRecordId: record.id);
    if (linkedReview == null) {
      return;
    }
    await ref
        .read(dateRecordControllerProvider.notifier)
        .addLinkedItem(
          recordId: record.id,
          linkedItem: linkedItemForReview(linkedReview),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결됨')));
    }
  }

  Future<void> _unlinkDateRecord(
    BuildContext context,
    WidgetRef ref,
    Review review,
  ) async {
    final recordId = review.dateRecordId;
    if (recordId == null) {
      return;
    }
    await ref
        .read(reviewControllerProvider.notifier)
        .unlinkDateRecord(review.id);
    await ref
        .read(dateRecordControllerProvider.notifier)
        .removeLinkedItem(
          recordId: recordId,
          linkedItem: linkedItemForReview(review),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('해제됨')));
    }
  }
}

class _DateRecordPickerSheet extends StatelessWidget {
  const _DateRecordPickerSheet({required this.records});

  final List<DateRecord> records;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '데이트 기록 선택',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: records.isEmpty
                    ? const Center(child: Text('없음'))
                    : ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            leading: const Icon(Icons.place_outlined),
                            title: Text(record.title),
                            subtitle: Text(
                              [
                                dates.formatDateLabel(record.date),
                                if (record.place != null) record.place!.name,
                              ].join(' · '),
                            ),
                            onTap: () => Navigator.of(context).pop(record),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewEditScreen extends ConsumerStatefulWidget {
  const ReviewEditScreen({this.reviewId, this.dateRecordId, super.key});

  final String? reviewId;
  final String? dateRecordId;

  @override
  ConsumerState<ReviewEditScreen> createState() => _ReviewEditScreenState();
}

class _ReviewEditScreenState extends ConsumerState<ReviewEditScreen> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _photoController = TextEditingController();
  final _photoLabels = <String>[];
  ReviewType _type = ReviewType.movie;
  double _rating = 4;
  var _didSeed = false;

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.reviewId == null
        ? null
        : ref.watch(reviewControllerProvider).reviewById(widget.reviewId!);
    if (widget.reviewId != null && review == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('리뷰를 찾을 수 없어요.')),
      );
    }
    _seed(review);
    final isEditing = review != null;
    final errorMessage = ref.watch(reviewControllerProvider).errorMessage;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '리뷰 편집' : '리뷰 추가')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ReviewForm(
              titleController: _titleController,
              memoController: _memoController,
              photoController: _photoController,
              photoLabels: _photoLabels,
              type: _type,
              rating: _rating,
              onTypeChanged: (type) => setState(() => _type = type),
              onRatingChanged: (rating) => setState(() => _rating = rating),
              onAppendMemo: _appendMemo,
              onAddPhoto: _addPhoto,
              onRemovePhoto: (label) {
                setState(() => _photoLabels.remove(label));
              },
              onSave: () => _save(review),
              actionLabel: isEditing ? '변경 저장' : '리뷰 저장',
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorPanel(message: errorMessage),
            ],
          ],
        ),
      ),
    );
  }

  void _seed(Review? review) {
    if (_didSeed) {
      return;
    }
    _didSeed = true;
    if (review == null) {
      return;
    }
    _titleController.text = review.title;
    _memoController.text = review.memo;
    _photoLabels
      ..clear()
      ..addAll(review.photoLabels);
    _type = review.type;
    _rating = review.rating;
  }

  Future<void> _save(Review? review) async {
    final controller = ref.read(reviewControllerProvider.notifier);
    final saved = await (review == null
        ? controller.addReview(
            type: _type,
            title: _titleController.text,
            rating: _rating,
            memo: _memoController.text,
            photoLabels: _photoLabels,
            dateRecordId: widget.dateRecordId,
          )
        : controller.updateReview(
            reviewId: review.id,
            type: _type,
            title: _titleController.text,
            rating: _rating,
            memo: _memoController.text,
            photoLabels: _photoLabels,
          ));
    if (saved == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(saved);
  }

  void _appendMemo(String text) {
    final current = _memoController.text.trim();
    _memoController.text = current.isEmpty ? text : '$current\n$text';
    _memoController.selection = TextSelection.collapsed(
      offset: _memoController.text.length,
    );
  }

  void _addPhoto() {
    final label = _photoController.text.trim();
    if (label.isEmpty) {
      return;
    }
    setState(() {
      _photoLabels.add(label);
      _photoController.clear();
    });
  }
}

class _ReviewForm extends StatelessWidget {
  const _ReviewForm({
    required this.titleController,
    required this.memoController,
    required this.photoController,
    required this.photoLabels,
    required this.type,
    required this.rating,
    required this.onTypeChanged,
    required this.onRatingChanged,
    required this.onAppendMemo,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onSave,
    required this.actionLabel,
  });

  final TextEditingController titleController;
  final TextEditingController memoController;
  final TextEditingController photoController;
  final List<String> photoLabels;
  final ReviewType type;
  final double rating;
  final ValueChanged<ReviewType> onTypeChanged;
  final ValueChanged<double> onRatingChanged;
  final ValueChanged<String> onAppendMemo;
  final VoidCallback onAddPhoto;
  final ValueChanged<String> onRemovePhoto;
  final VoidCallback onSave;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewDraftPreview(type: type, rating: rating),
          const SizedBox(height: 16),
          _FormLabel('종류'),
          const SizedBox(height: 8),
          _ReviewTypePicker(type: type, onChanged: onTypeChanged),
          const SizedBox(height: 16),
          _FormLabel('이름'),
          const SizedBox(height: 8),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: '예: 오늘 본 영화, 내추럴 와인, 파스타집',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _FormLabel('평점'),
          const SizedBox(height: 8),
          _RatingPicker(rating: rating, onChanged: onRatingChanged),
          const SizedBox(height: 16),
          _FormLabel('감상'),
          const SizedBox(height: 8),
          TextField(
            controller: memoController,
            decoration: const InputDecoration(
              hintText: '좋았던 점, 다시 보고 싶은 이유, 같이 나눈 얘기',
              border: OutlineInputBorder(),
            ),
            minLines: 5,
            maxLines: 8,
          ),
          const SizedBox(height: 10),
          _MemoPromptChips(type: type, onSelected: onAppendMemo),
          const SizedBox(height: 16),
          _FormLabel('사진'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: photoController,
                  decoration: const InputDecoration(
                    hintText: '사진 메모 또는 파일명',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onAddPhoto(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '사진 추가',
                onPressed: onAddPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
              ),
            ],
          ),
          if (photoLabels.isNotEmpty) ...[
            const SizedBox(height: 10),
            _EditablePhotoStrip(
              photoLabels: photoLabels,
              onRemovePhoto: onRemovePhoto,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.check),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDraftPreview extends StatelessWidget {
  const _ReviewDraftPreview({required this.type, required this.rating});

  final ReviewType type;
  final double rating;

  @override
  Widget build(BuildContext context) {
    final color = reviewTypeColor(type);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          _ReviewArtwork(type: type, size: 88),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  avatar: Text(reviewTypeEmoji(type)),
                  label: Text(reviewTypeLabel(type)),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                const SizedBox(height: 8),
                _Stars(rating: rating, size: 22),
                const SizedBox(height: 6),
                Text(
                  _ratingTone(rating),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _RatingBadge(rating: rating, size: 58),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onOpen});

  final Review review;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewThumbnail(review: review, size: 84),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RatingBadge(rating: review.rating, size: 44),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _Stars(rating: review.rating),
                    const SizedBox(height: 8),
                    Text(
                      review.memo.isEmpty
                          ? reviewTypeLabel(review.type)
                          : review.memo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    if (review.photoLabels.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '사진 ${review.photoLabels.length}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reviewTypeColor(review.type).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _ReviewThumbnail(review: review, size: 112),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  avatar: Text(reviewTypeEmoji(review.type)),
                  label: Text(reviewTypeLabel(review.type)),
                  backgroundColor: scheme.surface,
                ),
                const SizedBox(height: 8),
                Text(
                  review.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _Stars(rating: review.rating),
                const SizedBox(height: 6),
                Text(reviewRatingLabel(review)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTypePicker extends StatelessWidget {
  const _ReviewTypePicker({required this.type, required this.onChanged});

  final ReviewType type;
  final ValueChanged<ReviewType> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReviewType.values.map((candidate) {
            final selected = candidate == type;
            final color = reviewTypeColor(candidate);
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onChanged(candidate),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.16)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? color
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        reviewTypeEmoji(candidate),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reviewTypeLabel(candidate),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RatingPicker extends StatelessWidget {
  const _RatingPicker({required this.rating, required this.onChanged});

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RatingBadge(rating: rating, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Stars(rating: rating, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      _ratingTone(rating),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Slider(
            value: rating,
            min: 0,
            max: 5,
            divisions: 10,
            label: rating.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MemoPromptChips extends StatelessWidget {
  const _MemoPromptChips({required this.type, required this.onSelected});

  final ReviewType type;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final prompts = _memoPrompts(type);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: prompts.map((prompt) {
        return ActionChip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(Icons.add, size: 16),
          label: Text(prompt),
          onPressed: () => onSelected(prompt),
        );
      }).toList(),
    );
  }
}

class _ReviewArtwork extends StatelessWidget {
  const _ReviewArtwork({required this.type, required this.size});

  final ReviewType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = reviewTypeColor(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Text(
          reviewTypeEmoji(type),
          style: TextStyle(fontSize: size * 0.42),
        ),
      ),
    );
  }
}

class _ReviewThumbnail extends StatelessWidget {
  const _ReviewThumbnail({required this.review, required this.size});

  final Review review;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (review.photoLabels.isEmpty) {
      return _ReviewArtwork(type: review.type, size: size);
    }
    final color = reviewTypeColor(review.type);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_outlined),
          const SizedBox(height: 6),
          Text(
            review.photoLabels.first,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size * 0.11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditablePhotoStrip extends StatelessWidget {
  const _EditablePhotoStrip({
    required this.photoLabels,
    required this.onRemovePhoto,
  });

  final List<String> photoLabels;
  final ValueChanged<String> onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: photoLabels.map((label) {
        return InputChip(
          avatar: const Icon(Icons.photo_outlined, size: 18),
          label: Text(label),
          onDeleted: () => onRemovePhoto(label),
        );
      }).toList(),
    );
  }
}

class _ReviewPhotoGallery extends StatelessWidget {
  const _ReviewPhotoGallery({required this.photoLabels});

  final List<String> photoLabels;

  @override
  Widget build(BuildContext context) {
    return _ReviewSection(
      icon: Icons.photo_outlined,
      title: '사진',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: photoLabels.map((label) {
          return Container(
            width: 110,
            height: 82,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_outlined),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, required this.size});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _ratingColor(rating),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.28,
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 18});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        final icon = rating >= value
            ? Icons.star
            : rating >= value - 0.5
            ? Icons.star_half
            : Icons.star_border;
        return Icon(icon, size: size, color: _ratingColor(rating));
      }),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}

LinkedItem linkedItemForReview(Review review) {
  return LinkedItem(
    type: LinkedItemType.review,
    targetId: review.id,
    targetPath: '/reviews/${review.id}',
    title: review.title,
    subtitle: '${reviewTypeLabel(review.type)} · ${reviewRatingLabel(review)}',
    thumbnailUrl: review.photoLabels.firstOrNull,
    preview: review.memo,
    emoji: reviewTypeEmoji(review.type),
    createdAt: review.createdAt,
  );
}

String reviewRatingLabel(Review review) {
  return '별점 ${review.rating.toStringAsFixed(1)}';
}

Color reviewTypeColor(ReviewType type) {
  return switch (type) {
    ReviewType.movie => const Color(0xFF5D6B99),
    ReviewType.drama => const Color(0xFF8B6F9E),
    ReviewType.wine => const Color(0xFF9B4F63),
    ReviewType.restaurant => const Color(0xFFC07A45),
    ReviewType.place => const Color(0xFF4F8A78),
    ReviewType.other => const Color(0xFF6D7480),
  };
}

Color _ratingColor(double rating) {
  if (rating >= 4.5) {
    return const Color(0xFF3F8F5D);
  }
  if (rating >= 3.5) {
    return const Color(0xFF6B8F3F);
  }
  if (rating >= 2.5) {
    return const Color(0xFFC28A36);
  }
  return const Color(0xFF9B5C64);
}

String _ratingTone(double rating) {
  if (rating >= 4.5) {
    return '강력 추천';
  }
  if (rating >= 3.5) {
    return '좋았음';
  }
  if (rating >= 2.5) {
    return '무난함';
  }
  if (rating > 0) {
    return '아쉬움';
  }
  return '평점 없음';
}

List<String> _memoPrompts(ReviewType type) {
  return switch (type) {
    ReviewType.movie => const ['다시 보고 싶음', '대화할 거리 많음', '엔딩이 좋았음'],
    ReviewType.drama => const ['다음 화 궁금함', '캐릭터가 좋음', '같이 보기 좋음'],
    ReviewType.wine => const ['향이 좋음', '음식이랑 잘 맞음', '재구매 의사 있음'],
    ReviewType.restaurant => const ['분위기 좋음', '재방문 의사 있음', '대표 메뉴 좋음'],
    ReviewType.place => const ['산책하기 좋음', '사진 남기기 좋음', '다시 가고 싶음'],
    ReviewType.other => const ['기억에 남음', '같이 해서 좋음', '다음에도 하고 싶음'],
  };
}

String reviewTypeLabel(ReviewType type) {
  return switch (type) {
    ReviewType.movie => '영화',
    ReviewType.drama => '드라마',
    ReviewType.wine => '와인',
    ReviewType.restaurant => '식당',
    ReviewType.place => '장소',
    ReviewType.other => '기타',
  };
}

String reviewTypeEmoji(ReviewType type) {
  return switch (type) {
    ReviewType.movie => '🎬',
    ReviewType.drama => '📺',
    ReviewType.wine => '🍷',
    ReviewType.restaurant => '🍽️',
    ReviewType.place => '📍',
    ReviewType.other => '⭐',
  };
}
