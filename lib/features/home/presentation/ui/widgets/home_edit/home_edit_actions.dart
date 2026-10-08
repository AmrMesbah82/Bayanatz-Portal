part of '../../pages/home_edit.dart';

extension _HomeEditActions on _HomeEditPageMasterState {
  Widget _publishScheduleSection() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15.h),
            Text('Publish Date',
                style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
            SizedBox(height: 6.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picker = DatePicker();
                      final picked = await picker.showDatePicker(
                        context,
                        _publishDate != null ? [_publishDate] : [],
                        _publishDate ?? DateTime.now(),
                        CalendarDatePicker2Type.single,
                        firstDate: DateTime.now(),
                      );
                      if (picked != null && picked.isNotEmpty && picked.first != null) {
                        setState(() => _publishDate = picked.first);
                      }
                    },
                    child: Container(
                      height: 36.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _publishDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_publishDate!)
                                  : 'Select Date',
                              style: StyleText.fontSize12Weight400.copyWith(
                                color: _publishDate != null
                                    ? AppColors.text
                                    : AppColors.secondaryText,
                              ),
                            ),
                          ),
                          CustomSvg(
                            assetPath: 'assets/control/Calendar.svg',
                            width: 20.w, height: 20.h, fit: BoxFit.scaleDown,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_publishDate != null) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => setState(() => _publishDate = null),
                    child: Container(
                      height: 36.h, width: 36.h,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Center(child: Icon(Icons.close, color: Colors.red, size: 16.sp)),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 15.h),
          ],
        ),
      ),
      SizedBox(width: 200.sp),
      Expanded(child: Container()),
    ],
  );

  /// Shown when the user tries to open a second draft / second scheduled
  /// release. Nothing is written — the existing one has to be finished or
  /// removed first.
  void _slotBusyDialog({required bool isDraft}) {
    showConfirmDialog(
      context: context,
      title: isDraft ? 'DRAFT ALREADY EXISTS' : 'ALREADY SCHEDULED',
      subtitle: isDraft
          ? 'There is already an unpublished draft. Publish it, or remove it '
              'from the Draft tab, before saving another one.'
          : 'There is already a scheduled release. Publish it, or remove it '
              'from the Scheduled tab, before scheduling another one.',
      confirmLabel: 'OK',
      cancelLabel: '',
      onConfirm: () {},
    );
  }

  Widget _bottomButtons(HomeCmsCubit cubit) {
    final bool canPublish  = _isFormValid;
    final bool isScheduled =
        _publishDate != null && _publishDate!.isAfter(DateTime.now());

    // Each slot holds one version at a time. You can keep updating the one you
    // are editing, but you cannot start a second one on top of it.
    final bool draftBlocked     = !cubit.canSaveDraft;
    final bool scheduledBlocked = !cubit.canSaveScheduled;

    // Shared action buttons — style lives in core/main_widgets/edit_action_buttons.dart
    return EditActionButtons(
      publishEnabled: canPublish,
      isSaving:       _isSaving,
      publishLabel:   isScheduled ? 'Schedule' : 'Publish',
      publishColor:   isScheduled ? ColorPick.scheduled : null,
      // BUG-53: the preview showed the PUBLISHED text — copy the form into
      // the cubit first so it shows the edits being made.
      onPreview: () {
        _syncFormToCubit(cubit);
        navigateTo(context, HomePreviewPageMaster());
      },
      onPublish: () {
        // Scheduling writes the scheduled document; publishing writes the live
        // one. Neither touches the other.
        if (isScheduled && scheduledBlocked) {
          _slotBusyDialog(isDraft: false);
          return;
        }
        showPublishConfirmDialog(
          context: context,
          title: isScheduled ? 'SCHEDULE PAGE' : 'PUBLISH PAGE',
          subtitle: isScheduled
              ? 'Your changes will be scheduled for ${DateFormat('dd/MM/yyyy').format(_publishDate!)}. The published version stays live until then.'
              : 'Do you want to publish this page now? This replaces the live version.',
          confirmLabel: isScheduled ? 'Schedule' : 'Publish',
          onConfirm: () => _save(
            cubit,
            publishStatus: isScheduled ? 'scheduled' : 'published',
            scheduledPublishDate: isScheduled ? _publishDate : null,
          ),
        );
      },
      onDiscard: () {
        if (_isEditingDraft) {
          showPublishConfirmDialog(
            context: context,
            title: 'DISCARD DRAFT',
            subtitle:
                'Are you sure you want to discard this draft? The published version will remain unchanged.',
            confirmLabel: 'Discard',
            onConfirm: () => cubit.removeDraft(),
          );
        } else {
          confirmDiscard(context, // BUG-75: always back to Web Page → Home, never the dashboard.
            onDiscard: _goToHomeTab);
        }
      },
      onSaveForLater: () {
        if (draftBlocked) {
          _slotBusyDialog(isDraft: true);
          return;
        }
        showPublishConfirmDialog(
          context: context,
          title: 'SAVE AS DRAFT',
          subtitle:
              'Your changes will be saved as a draft. The published version stays live and unchanged.',
          confirmLabel: 'Save Draft',
          onConfirm: () => _save(cubit, publishStatus: 'draft'),
        );
      },
    );
  }

  Widget _accordion({
    required String key,
    required String title,
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

  Widget _gap() => SizedBox(height: 10.h);
}
