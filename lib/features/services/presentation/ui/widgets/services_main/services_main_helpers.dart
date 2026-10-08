// ******************* FILE INFO *******************
// Part of: services_main.dart
// Contains: _navigateToCreate, _navigateToEdit, _confirmDelete, _actionBtn,
//           _lastUpdatedRow, _journeyGrid, _journeyMiniCard, _accordion,
//           _readField, _readFieldRtl

part of '../../pages/services_main/services_main.dart';

extension _ServicesMainHelpers on _ServicesMainPageMasterState {
  // ── Navigate helpers ──────────────────────────────────────────────────────────
  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BlogCubit>(),
          child: const BlogCreateEditPage(),
        ),
      ),
    ).then((_) => context.read<BlogCubit>().load());
  }

  void _navigateToEdit(BlogPostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BlogCubit>(),
          child: BlogCreateEditPage(existing: post),
        ),
      ),
    ).then((_) => context.read<BlogCubit>().load());
  }

  Future<void> _confirmDelete(BlogPostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text(
            'Delete "${post.question.en.isNotEmpty ? post.question.en : 'this post'}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<BlogCubit>().deletePost(post.id);
    }
  }

  // ── Action button ─────────────────────────────────────────────────────────────
  Widget _actionBtn({
    required String       label,
    required VoidCallback onTap,
    required bool         outlined,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: outlined ? ColorPick.background : ColorPick.primary,
          borderRadius: BorderRadius.circular(6.r),
          border: outlined ? Border.all(color: ColorPick.primary) : null,
        ),
        child: Center(
          child: Text(label,
              style: StyleText.fontSize13Weight500.copyWith(
                  color: outlined ? ColorPick.primary : Colors.white)),
        ),
      ),
    );
  }

  // ── Last updated row ──────────────────────────────────────────────────────────
  Widget _lastUpdatedRow({required VoidCallback onEdit, DateTime? lastUpdated}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
              color: ColorPick.white, borderRadius: BorderRadius.circular(4.r)),
          child: Text(
            'Last Updated On ${_fmtDate(lastUpdated)}',
            style: StyleText.fontSize13Weight500.copyWith(color: ColorPick.primary),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            width: 130.w, height: 36.h,
            decoration: BoxDecoration(
                color: ColorPick.white, borderRadius: BorderRadius.circular(4.r)),
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Edit Details',
                    style: StyleText.fontSize14Weight500.copyWith(color: Colors.black)),
                SizedBox(width: 6.w),
                CustomSvg(
                    assetPath: "assets/control/edit_icon_pick.svg",
                    width: 20.w, height: 20.h,
                    fit: BoxFit.scaleDown, color: ColorPick.primary),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Open the Digital Journey row / card layout screen ─────────────────────────
  void _openJourneyLayout() {
    final cubit = context.read<ServiceCmsCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: ServicesDigitalLayoutPage(model: cubit.current),
        ),
      ),
    );
  }

  // ── Journey grid ──────────────────────────────────────────────────────────────
  //
  // The grid follows the saved layout: rowSizes says how many cards each row
  // holds, and the flat journeyItems list is chunked by it. Documents saved
  // before the layout screen existed have no rowSizes — those fall back to the
  // old fixed four-across grouping.
  Widget _journeyGrid(List<JourneyItemModel> items) {
    final List<int> sizes = context.read<ServiceCmsCubit>().current.rowSizes;
    final List<List<JourneyItemModel>> rows = [];

    if (sizes.isEmpty) {
      for (int i = 0; i < items.length; i += 4) {
        rows.add(items.skip(i).take(4).toList());
      }
    } else {
      int i = 0;
      for (final n in sizes) {
        if (i >= items.length) break;
        rows.add(items.skip(i).take(n).toList());
        i += n;
      }
      while (i < items.length) {
        rows.add(items.skip(i).take(4).toList());
        i += 4;
      }
    }
    return Column(
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Each row spans the full width, split by however many cards
                // the saved layout gave it.
                ...row.map((item) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      // Tapping any card opens the row / card layout screen.
                      onTap: _openJourneyLayout,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: _journeyMiniCard(item),
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _journeyMiniCard(JourneyItemModel item) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w, height: 28.w,
            decoration: BoxDecoration(
                color: ColorPick.preview, borderRadius: BorderRadius.circular(6.r)),
            child: item.iconUrl.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: Padding(
                padding: EdgeInsets.all(7.r),
                child: NetworkImageView(url: item.iconUrl,
                    width: 14.w, height: 14.w, fit: BoxFit.contain),
              ),
            )
                : Icon(Icons.miscellaneous_services_outlined,
                size: 16.sp, color: ColorPick.primary),
          ),
          SizedBox(height: 6.h),
          Text(
            FormatHelper.capitalize(item.title.en.isNotEmpty ? item.title.en : 'Title',),
            style: StyleText.fontSize12Weight600
                .copyWith(color: const Color(0xFF1A1A1A)),
          ),
          SizedBox(height: 4.h),
          Text(
            item.description.en.isNotEmpty ? item.description.en : 'Description',
            style: StyleText.fontSize12Weight400
                .copyWith(color: AppColors.secondaryBlack, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Accordion ─────────────────────────────────────────────────────────────────
  Widget _accordion({
    required String       key,
    required String       title,
    required List<Widget> children,
  }) {
    final isOpen = _open[key] ?? true;
    return CustomAccordion(
      title:    title,
      isOpen:   isOpen,
      onToggle: () => setState(() => _open[key] = !isOpen),
      child:    Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ── Read-only field LTR ───────────────────────────────────────────────────────
  Widget _readField(String label, String value, {double height = 36}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 20.h),
      Text(label, style: StyleText.fontSize14Weight500.copyWith(color: AppColors.text)),
      SizedBox(height: 4.h),
      Container(
        width: double.infinity, height: height.h,
        padding: EdgeInsets.symmetric(
            horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
        alignment: height > 36 ? Alignment.topLeft : Alignment.centerLeft,
        child: Text(value,
          style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
          maxLines: height > 36 ? 4 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  // ── Read-only field RTL ───────────────────────────────────────────────────────
  Widget _readFieldRtl(String label, String value, {double height = 36}) =>
      Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Text(label,
                style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
            SizedBox(height: 4.h),
            Container(
              width: double.infinity, height: height.h,
              padding: EdgeInsets.symmetric(
                  horizontal: 10.w, vertical: height > 36 ? 8.h : 0),
              decoration: BoxDecoration(
                  color: AppColors.card, borderRadius: BorderRadius.circular(4.r)),
              alignment: height > 36 ? Alignment.topRight : Alignment.centerRight,
              child: Text(
                value.isEmpty ? 'أكتب هنا' : value,
                style: StyleText.fontSize12Weight400
                    .copyWith(color: AppColors.secondaryText),
                textDirection: TextDirection.rtl,
                maxLines: height > 36 ? 4 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
