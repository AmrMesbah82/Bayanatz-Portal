part of '../../pages/careers_main_page.dart';

class _InternCard extends StatefulWidget {
  final InternModel intern;
  final InternCubit cubit;
  final bool        listMode;
  const _InternCard({
    required this.intern,
    required this.cubit,
    this.listMode = false,
  });

  @override
  State<_InternCard> createState() => _InternCardState();
}

class _InternCardState extends State<_InternCard> {
  bool _hovered = false;

  // ── CMS branding primary color (from Firebase via MainCmsCubit) ──────────
  Color _cmsPrimary(BuildContext context) {
    final MainCmsState state = context.watch<MainCmsCubit>().state;
    final String hex = switch (state) {
      MainCmsLoaded(:final data) => data.branding.primaryColor,
      MainCmsSaved(:final data)  => data.branding.primaryColor,
      _                          => '',
    };
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {}
    return ColorPick.primary; // fallback
  }

  void _openEditPage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
          value: widget.cubit, child: AddInternPage(existing: widget.intern)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final intern = widget.intern;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _openEditPage(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
          child: _gridLayout(context, intern),
        ),
      ),
    );
  }

  Widget _gridLayout(BuildContext context, InternModel intern) {
    final double avatarSz = 52.w;
    final double leftColW = 110.w;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: leftColW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatar(intern, avatarSz),
              SizedBox(height: 8.h),
              Text(intern.fullName,
                  textAlign: TextAlign.center,
                  style: StyleText.fontSize13Weight600.copyWith(
                      fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.black87)),
              SizedBox(height: 3.h),
              Text(intern.degrees,
                  textAlign: TextAlign.center,
                  style: StyleText.fontSize11Weight400.copyWith(
                      fontSize: 9.sp, color: Colors.black45, height: 1.4)),
              SizedBox(height: 3.h),
              if (intern.position.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: ColorPick.primary,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Padding(
                    padding:  EdgeInsets.symmetric(horizontal: 10.sp,vertical: 5.sp),
                    child: Column(
                      children: [
                        SizedBox(height: 3.h),
                        Text(intern.position,
                            textAlign: TextAlign.center,
                            style: StyleText.fontSize11Weight400.copyWith(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 8.h),
              // Wrap(
              //   spacing: 4.w, runSpacing: 3.h, alignment: WrapAlignment.center,
              //   children: intern.tags.map((tag) => Container(
              //     padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              //     decoration: BoxDecoration(
              //         color: ColorPick.primary, borderRadius: BorderRadius.circular(4.r)),
              //     child: Text(tag,
              //         style: StyleText.fontSize10Weight700.copyWith(
              //             fontSize: 9.sp, fontWeight: FontWeight.w600, color: Colors.white)),
              //   )).toList(),
              // ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(intern.joinDateLabel,
                  style: StyleText.fontSize10Weight400.copyWith(
                      fontSize: 9.sp, color: Colors.black45)),
              SizedBox(height: 12.h),
              Text('What Have I Learned',
                  style: StyleText.fontSize13Weight600.copyWith(
                      fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.secondaryText)),
              SizedBox(height: 6.h),
              Text(intern.whatHaveILearned,
                  style: StyleText.fontSize12Weight400.copyWith(
                      fontSize: 10.sp, height: 1.5, color: AppColors.text),
                  maxLines: 4, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatar(InternModel intern, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ColorPick.primary, width: 1.5),
        color: const Color(0xFFE0E0E0),
        image: intern.photoUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(intern.photoUrl), fit: BoxFit.cover)
            : null,
      ),
      child: intern.photoUrl.isEmpty
          ? Center(child: Icon(Icons.person, color: Colors.grey, size: size * 0.5))
          : null,
    );
  }

  void _confirmDelete(BuildContext context, InternModel intern) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text('Delete Intern',
            style: StyleText.fontSize16Weight600.copyWith(color: Colors.black87)),
        content: Text('Are you sure you want to delete ${intern.fullName}?',
            style: StyleText.fontSize14Weight400.copyWith(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: StyleText.fontSize13Weight500.copyWith(color: AppColors.secondaryText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.cubit.delete(intern.id);
            },
            child: Text('Delete',
                style: StyleText.fontSize13Weight600.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INTERN EXPORT DIALOG  (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════
