// ******************* FILE INFO *******************
// Part of: main_edit.dart
// Contains: _buildFooterColumn, _buildLabelRow, _linksSection, _linkItem

part of '../../pages/main_edit.dart';

extension _HomeEditSections2 on _MainEditPageState {
  // ─── Footer Column ──────────────────────────────────────────────────────────
  Widget _buildFooterColumn(int colIndex) {
    final col              = _footerColumns[colIndex];
    final labels           = col['labels'] as List<Map<String, dynamic>>;
    final navDropdownItems = _buildNavDropdownItems();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 15.h),
      if (colIndex > 0) SizedBox(height: 12.h),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${colIndex + 1}${_ord(colIndex + 1)} Column',
              style: StyleText.fontSize14Weight600
                  .copyWith(color: AppColors.text)),
          _removeBtn(
            label: 'Remove',
            onTap: () => setState(() {
              final removed = _footerColumns.removeAt(colIndex);
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _disposeColumn(removed));
            }),
          ),
        ],
      ),
      SizedBox(height: 8.h),

      // BUG-212: Group Title EN / AR are editable text (like the labels);
      // the column's link is chosen separately below. Picking a link only
      // pre-fills titles that are still empty.
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomTextField(
              label: 'Group Title',
              required: true,
              controller: col['titleEn'] as TextEditingController,
              hint: 'e.g. Terms of Service',
              fillColor: Colors.white,
              height: 36,
              submitted: _submitted,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: CustomTextField(
                label: 'عنوان المجموعة',
                required: true,
                controller: col['titleAr'] as TextEditingController,
                hint: 'أدخل النص هنا',
                fillColor: Colors.white,
                height: 36,
                submitted: _submitted,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 10.h),
      Row(
        children: [
          Expanded(
            child: CustomDropdown<String>(
              label: 'Group Title Link',
              hint: 'Select page',
              value: col['route'] as String?,
              items: navDropdownItems
                  .map((m) => DropdownItem<String>(
                      value: m['key']!, label: m['value']!))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  col['route'] = val;
                  final enCtrl = col['titleEn'] as TextEditingController;
                  final arCtrl = col['titleAr'] as TextEditingController;
                  if (val.isEmpty) return;
                  String en = '', ar = '';
                  final idx = _navRoutes.indexOf(val);
                  if (idx != -1) {
                    en = _navBtns[idx]['nameEn']!.text;
                    ar = _navBtns[idx]['nameAr']!.text;
                  } else {
                    final dest = _kGroupTitleDestinations.firstWhere(
                      (d) => d['key'] == val,
                      orElse: () => const <String, String>{},
                    );
                    en = dest['value'] ?? '';
                    ar = dest['ar'] ?? '';
                  }
                  if (enCtrl.text.trim().isEmpty) enCtrl.text = en;
                  if (arCtrl.text.trim().isEmpty) arCtrl.text = ar;
                });
              },
            ),
          ),
          SizedBox(width: 8.w),
          const Expanded(child: SizedBox()),
        ],
      ),
      SizedBox(height: 10.h),

      ...List.generate(labels.length, (li) => _buildLabelRow(colIndex, li)),
      Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: _addLabelBtn(
            onTap: () => setState(() => labels.add(_newLabelRow()))),
      ),
    ]);
  }

  // ─── Label Row ──────────────────────────────────────────────────────────────
  Widget _buildLabelRow(int colIndex, int labelIndex) {
    final labels =
        _footerColumns[colIndex]['labels'] as List<Map<String, dynamic>>;
    final label = labels[labelIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Button name first (EN / AR) ────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Label',
                labelStyle:StyleText.fontSize14Weight500
                    .copyWith(color: AppColors.text) ,
                hint: 'Text Here',
                required: true,
                controller: label['en'] as TextEditingController,
                height: 36,
                submitted: _submitted,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: CustomTextField(
                  label: 'التسمية',
                  required: true,
                  fillColor: Colors.white,
                  hint: 'أدخل النص هنا',
                  controller: label['ar'] as TextEditingController,
                  height: 36,
                  submitted: _submitted,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // ── Navigation destination second ──────────────────────────────────
        Stack(
          alignment: AlignmentGeometry.topRight,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomDropdown<String>(
                          label: 'Navigate To',
                          hint: 'Select destination',
                          value: label['route'] as String?,
                          items: _kLabelDestinations
                              .map((m) => DropdownItem<String>(
                                  value: m['key']!, label: m['value']!))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => label['route'] = val),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 0.sp),
                Expanded(child: Container()),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        final removed = labels.removeAt(labelIndex);
                        WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _disposeLabel(removed));
                      }),
                      child: Container(
                        width: 16.w,
                        height: 16.h,
                        decoration: const BoxDecoration(
                            color: ColorPick.red, shape: BoxShape.circle),
                        child: Icon(Icons.remove,
                            color: Colors.white, size: 16.sp),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
              ],
            ),
          ],
        ),
        // Spacing between "Navigate To" and the next "Label" row.
        SizedBox(height: 10.h),
      ],
    );
  }

  // ─── Social Links Section ───────────────────────────────────────────────────
  Widget _linksSection() => _accordion(
        key: 'links',
        title: 'Links',
        children: [
          ...List.generate((_links.length / 2).ceil(), (rowIndex) {
            final left  = rowIndex * 2;
            final right = left + 1;
            return Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _linkItem(left)),
                  SizedBox(width: 16.w),
                  right < _links.length
                      ? Expanded(child: _linkItem(right))
                      : const Expanded(child: SizedBox()),
                ],
              ),
            );
          }),
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: () => setState(() => _links.add(_LinkItem())),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                  color: const Color(0xFF797979),
                  borderRadius: BorderRadius.circular(4.r)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, size: 14.sp, color: Colors.white),
                SizedBox(width: 4.w),
                Text('Link',
                    style: StyleText.fontSize12Weight500
                        .copyWith(color: Colors.white)),
              ]),
            ),
          ),
        ],
      );

  // ─── Link Item ──────────────────────────────────────────────────────────────
  Widget _linkItem(int i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('Icon'),
              GestureDetector(
                onTap: () => setState(() {
                  final removed = _links.removeAt(i);
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => removed.dispose());
                }),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                      color: ColorPick.red,
                      borderRadius: BorderRadius.circular(4.r)),
                  child: Text('Remove',
                      style: StyleText.fontSize11Weight400
                          .copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _imgBox(
                picked: _links[i].icon,
                placeholderAsset: 'assets/control/edit_icon_pick.svg',
                pickIconAsset: 'assets/control/edit_icon_pick.svg',
                onPick: () async {
                  final p = await _pickImage();
                  if (p != null) setState(() => _links[i].icon = p);
                },
              ),
              if (_submitted && _links[i].icon.isEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Text(
                    'SVG icon required',
                    style: StyleText.fontSize12Weight400
                        .copyWith(color: ColorPick.red),
                  ),
                ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 8.h),
          CustomTextField(
            label: 'Insert Link',
            // Visibility switch pinned to the END of the field, matching the
            // Navigation Items Status switch.
            labelTrailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Visibility',
                    style: StyleText.fontSize12Weight500
                        .copyWith(color: AppColors.text)),
                SizedBox(width: 6.w),
                FlutterSwitch(
                  width: 35.sp,
                  height: 20.sp,
                  padding: 3.sp,
                  borderRadius: 20.sp,
                  toggleSize: 16.sp,
                  activeColor: ColorPick.primary,
                  inactiveColor: Colors.grey.withValues(alpha: .16),
                  value: _links[i].visibility,
                  onToggle: (val) =>
                      setState(() => _links[i].visibility = val),
                ),
              ],
            ),
            required: true,
            fillColor: Colors.white,
            hint: 'Insert Links',
            controller: _links[i].text,
            height: 36,
            submitted: _submitted,
          ),
        ],
      );
}
