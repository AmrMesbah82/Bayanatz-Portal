part of '../../pages/home_main.dart';

extension _HomeMainBuilders on _HomeMainPageMasterState {
  Widget _subNavBar() => Container(
    width: 1000.w,
    decoration: BoxDecoration(color: ColorPick.white, borderRadius: BorderRadius.circular(4.r)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_subNavLabels.length, (i) {
        final active = _subNavIndex == i;
        return GestureDetector(
          onTap: () {
            setState(() => _subNavIndex = i);
            switch (i) {
              case 0: context.go('/admin/dashboard');
              case 1: break;
              case 2: Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesMainPageMaster()));
              case 3: context.go('/admin/about-cms');
              case 4: context.go('/admin/contact-cms');
              case 5: context.go('/admin/careers-cms');
            }
          },
          child: Container(
            margin: EdgeInsets.only(right: 4.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: active ? ColorPick.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(_subNavLabels[i],
                style: StyleText.fontSize14Weight500.copyWith(color: active ? Colors.white : AppColors.text)),
          ),
        );
      }),
    ),
  );

  // ── Slot helpers ──────────────────────────────────────────────────────────

  String _slotLabel(HomeVersionSlot slot) => switch (slot) {
        HomeVersionSlot.published => 'Published',
        HomeVersionSlot.scheduled => 'Scheduled',
        HomeVersionSlot.draft     => 'Draft',
      };

  HomePageModel? _slotModel(HomeCmsCubit cubit, HomeVersionSlot slot) =>
      switch (slot) {
        HomeVersionSlot.published => cubit.publishedModel,
        HomeVersionSlot.scheduled => cubit.scheduledModel,
        HomeVersionSlot.draft     => cubit.draftModel,
      };

  // ── Page body ─────────────────────────────────────────────────────────────

  Widget _body(HomeCmsCubit cubit, List<HomeVersionSlot> slots) {
    final HomePageModel? active = _slotModel(cubit, _activeSlot);

    // Published always exists as a tab, but the document may still be empty on
    // a brand-new site.
    final HomePageModel data = active ?? cubit.current;

    // Only a scheduled release or a draft can be thrown away. The live page
    // is never removable from here.
    final bool canRemove = _activeSlot != HomeVersionSlot.published;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Home', style: StyleText.fontSize45Weight600.copyWith(color: ColorPick.primary, fontWeight: FontWeight.w700)),
            const Spacer(),

            // ── Remove this version ───────────────────────────────────────
            if (canRemove) ...[
              GestureDetector(
                onTap: () => _confirmRemove(cubit, _activeSlot),
                child: Container(
                  height: 36.h,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: const Color(0xFFE53935)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18.sp, color: const Color(0xFFE53935)),
                      SizedBox(width: 6.w),
                      Text(
                        'Remove ${_slotLabel(_activeSlot)}',
                        style: StyleText.fontSize14Weight500
                            .copyWith(color: const Color(0xFFE53935)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
            ],

            GestureDetector(
              onTap: () => navigateTo(context, HomePreviewPageMaster()),
              child: Container(
                width: 130.w, height: 36.h,
                decoration: BoxDecoration(color: ColorPick.primary, borderRadius: BorderRadius.circular(6.r)),
                child: Center(child: Text('Preview Screen',
                    style: StyleText.fontSize14Weight500.copyWith(color: Colors.white))),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // ── Status tabs — only the versions that actually exist ────────────
        SizedBox(
          height: 40.h,
          child: Row(
            children: slots.map((slot) {
              final isActive = _activeSlot == slot;
              return Padding(
                padding: EdgeInsets.only(right: 24.w),
                child: GestureDetector(
                  onTap: () => setState(() => _activeSlot = slot),
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _slotLabel(slot),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? ColorPick.primary : AppColors.secondaryText,
                          ),
                        ),
                        Container(height: 2, color: isActive ? ColorPick.primary : Colors.transparent),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 12.h),

        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(color: ColorPick.white, borderRadius: BorderRadius.circular(4.r)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_buildLastUpdatedText(data),
                    style: StyleText.fontSize13Weight500.copyWith(color: ColorPick.primary)),
              ]),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // Open the editor on the version being viewed, so editing the
                // draft edits the draft — not whatever loaded first.
                cubit.editSlot(_activeSlot);
                // BUG-276: the editor has its own URL now.
                GoRouter.of(context).go('/admin/home-page/edit');
              },
              child: Container(
                width: 130.w, height: 36.h,
                decoration: BoxDecoration(color: ColorPick.white, borderRadius: BorderRadius.circular(4.r)),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Edit Details', style: StyleText.fontSize14Weight500.copyWith(color: Colors.black)),
                  SizedBox(width: 6.w),
                  CustomSvg(assetPath: "assets/control/edit_icon_pick.svg",
                      width: 20.w, height: 20.h, fit: BoxFit.scaleDown, color: ColorPick.primary),
                ])),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        SizedBox(
          height: 900.h,
          child: _buildSlotContent(active, _activeSlot),
        ),
        SizedBox(height: 40.h),
      ],
    );
  }

  String _buildLastUpdatedText(HomePageModel data) {
    if (data.lastUpdatedAt != null) {
      final d = data.lastUpdatedAt!;
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return 'Last Updated On ${d.day} ${months[d.month]} ${d.year}';
    }
    return 'Last Updated On —';
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    switch (status) {
      case 'published':
        bgColor = ColorPick.primary.withValues(alpha: 0.15);
        textColor = ColorPick.primary;
        label = 'Published';
        break;
      case 'scheduled':
        bgColor = ColorPick.scheduled.withValues(alpha: 0.15);
        textColor = ColorPick.scheduled;
        label = 'Scheduled';
        break;
      case 'draft':
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = 'Draft';
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4.r)),
      child: Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  /// Renders one stored version. [data] is null only for the Published tab on
  /// a site that has never been published — the other tabs only exist when
  /// their document does.
  Widget _buildSlotContent(HomePageModel? data, HomeVersionSlot slot) {
    if (data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 48.sp, color: AppColors.secondaryText),
            SizedBox(height: 16.h),
            Text('No published version yet',
                style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text)),
            SizedBox(height: 8.h),
            Text('Click "Edit Details" → "Publish" to publish your home page.',
                style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (slot == HomeVersionSlot.scheduled &&
              data.scheduledPublishDate != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: ColorPick.scheduled.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: ColorPick.scheduled.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.schedule, color: ColorPick.scheduled, size: 18.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Scheduled to publish on ${DateFormat('d MMM yyyy').format(data.scheduledPublishDate!)}' /* BUG-304 */
                    ' — the published version stays live until then.',
                    style: StyleText.fontSize13Weight500.copyWith(color: ColorPick.scheduled),
                  ),
                ),
              ]),
            ),
            SizedBox(height: 12.h),
          ],

          if (slot == HomeVersionSlot.draft) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(children: [
                Icon(Icons.drafts_outlined, color: Colors.grey.shade700, size: 18.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Unpublished draft — the published version stays live until you publish it.',
                    style: StyleText.fontSize13Weight500.copyWith(color: Colors.grey.shade700),
                  ),
                ),
              ]),
            ),
            SizedBox(height: 12.h),
          ],

          _accordion(key: 'headings', title: 'Headings', children: [
            SizedBox(height: 15.h), _headingsReadOnly(data),
          ]),
          SizedBox(height: 10.h),
          _accordion(key: 'navButtons', title: 'Navigation Button', children: [
            SizedBox(height: 15.h), _navButtonsReadOnly(data),
          ]),
          SizedBox(height: 10.h),
          _accordion(key: 's1', title: 'Section 1 - Left', children: [SizedBox(height: 15.h), _sectionView(data, 0)]),
          SizedBox(height: 10.h),
          _accordion(key: 's2', title: 'Section 2 - Left Corner', children: [SizedBox(height: 15.h), _sectionView(data, 1)]),
          SizedBox(height: 10.h),
          _accordion(key: 's3', title: 'Section 3 - Right', children: [SizedBox(height: 15.h), _sectionView(data, 2)]),
          SizedBox(height: 10.h),
          _accordion(key: 's4', title: 'Section 4 - Right Corner', children: [SizedBox(height: 15.h), _sectionView(data, 3)]),
        ],
      ),
    );
  }
}
