part of '../../pages/services_main/services_main.dart';

class _BlogCard extends StatelessWidget {
  final BlogPostModel post;
  final VoidCallback  onEdit;
  final VoidCallback  onDelete;

  const _BlogCard({
    required this.post,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor => switch (post.status) {
    'published' => ColorPick.activeColor,
    'inactive'  => ColorPick.inactiveColor,
    'draft'     => ColorPick.draftColor,
    'removed'   => ColorPick.removedColor,
    _           => ColorPick.draftColor,
  };

  String get _statusLabel => switch (post.status) {
    'published' => 'Active',
    'inactive'  => 'Inactive',
    'draft'     => 'Draft',
    'removed'   => 'Removed',
    _           => 'Draft',
  };

  // BUG-196: "Inactive Since <posting date>" / "Started Since …" used the
  // POSTING date. A changed status now shows the date it changed, and a
  // draft says "Draft since" ("Started" was unclear).
  String get _datePrefix => switch (post.status) {
    'published' => 'Posted:',
    'inactive'  => 'Inactive since',
    'draft'     => 'Draft since',
    'removed'   => 'Removed on',
    _           => '',
  };

  DateTime? get _cardDate => post.status == 'published'
      ? post.createdAt
      : (post.statusChangedAt ?? post.createdAt);

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final String cleanUrl = post.imageUrl.trim();
    final bool hasImage   = cleanUrl.isNotEmpty;

    return GestureDetector(
      onTap: onEdit,
      child: Container(

        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10.r),
        ),
        // ── TWO COLUMNS, not three stacked rows ──────────────────────────
        // The card used to be: [date + badge] / [text | image] / [Read More].
        // That put the text in a middle band whose height was decided by the
        // image beside it, so the title and description were clipped to two
        // lines each no matter how much room the card had.
        //
        // Now the card is one Row of two columns: everything textual on the
        // left, everything image-ish on the right. The Row takes the height of
        // its TALLER column, so the text is free to run past the bottom of the
        // image instead of being squeezed to fit next to it.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left column: date, title, description ────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '$_datePrefix ',
                        style: StyleText.fontSize10Weight400
                            .copyWith(color: AppColors.secondaryText),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Flexible(
                        child: Text(
                          _fmtDate(_cardDate), // BUG-196
                          style: StyleText.fontSize10Weight400
                              .copyWith(color: AppColors.text),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    post.question.en.isNotEmpty
                        ? post.question.en
                        : 'Untitled',
                    style: StyleText.fontSize13Weight600.copyWith(
                      color: ColorPick.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    post.shortDescription.en.isNotEmpty
                        ? post.shortDescription.en
                        : 'Short Description...',
                    style: StyleText.fontSize12Weight400
                        .copyWith(color: AppColors.secondaryText),
                    // Was 2. The description is the whole point of the card and
                    // it no longer has to end where the image ends.
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),

            // ── Right column: status, image, Read More ───────────────────
            SizedBox(
              width: 110.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      _statusLabel,
                      style: StyleText.fontSize12Weight500
                          .copyWith(color: _statusColor),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Image — auto-detects SVG vs raster via XHR.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: hasImage
                        ? _XhrImage(
                            url:    cleanUrl,
                            width:  110.w,
                            height: 80.h,
                          )
                        : _imgPlaceholder(),
                  ),
                  SizedBox(height: 12.h),

                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 7.h),
                      decoration: BoxDecoration(
                        color: ColorPick.primary,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Read More',
                        style: StyleText.fontSize12Weight500
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 110.w, height: 80.h,
    decoration: BoxDecoration(
      color: ColorPick.background,
      borderRadius: BorderRadius.circular(8.r),
    ),
    child: Icon(Icons.image_outlined, size: 24.sp, color: AppColors.secondaryText),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// XHR image loader — auto-detects SVG vs raster (PNG/JPG/WebP)
// Works on Flutter Web, bypasses CORS for Firebase Storage
// ══════════════════════════════════════════════════════════════════════════════
