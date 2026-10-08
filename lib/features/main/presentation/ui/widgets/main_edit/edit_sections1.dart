// ******************* FILE INFO *******************
// Part of: main_edit.dart
// Contains: _accordion, _logoAndBrandingSection, _navSection,
//           _buildNavItemRow, _bottomActions, _footerSection, _gap

part of '../../pages/main_edit.dart';

extension _HomeEditSections1 on _MainEditPageState {
  Widget _gap() => SizedBox(height: 10.h);

  // ─── Bottom buttons ────────────────────────────────────────────────────────
  Widget _bottomActions(MainCmsCubit cubit) {
    // Two conditions, not one: every required field is filled AND something
    // has actually changed since the page loaded. A complete but untouched
    // form has nothing to publish.
    final bool canPublish = _isFormValid && _isDirty;

    // Shared action buttons — style lives in core/main_widgets/edit_action_buttons.dart
    return EditActionButtons(
      publishEnabled: canPublish,
      // BUG-76: this page has an exact change check (_isDirty — it includes
      // the nav Status switches, colours and fonts). The shared text-only
      // dirty flag never saw a switch, so "Careers: Status OFF" alone could
      // not be published.
      requireChanges: false,
      // BUG-59: a blocked Publish now names the field that is missing.
      onPublishBlocked: () {
        final msg = _getValidationError() ??
            (_isDirty ? null : 'Nothing to publish — no changes made yet');
        if (msg == null) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: ColorPick.primary,
          behavior: SnackBarBehavior.floating,
        ));
      },
      publishDisabledTooltip: _isFormValid
          ? 'Nothing to publish — no changes made yet'
          : 'Fill in all required fields to publish',
      onPreview: () => navigateTo(context, MainPreviewPage()),
      onPublish: () {
        showPublishConfirmDialog(
          // BUG-79: this is the Main (site frame) page, not the Homepage.
          title: 'EDITING MAIN DETAILS',
          subtitle: 'Do you want to save the changes made to the Main page (logo, colours, menu and footer)?',
          context: context,
          onConfirm: () => _save(cubit, publishStatus: 'published'),
        );
      },
      onDiscard: () {
        confirmDiscard(context, // BUG-75: Discard used to pop into whatever was underneath — often
          // the Home dashboard. It now always returns to Web Page → Main.
          onDiscard: _goToMainTab);
      },
    );
  }

  // ─── Accordion ─────────────────────────────────────────────────────────────
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ── Logo & Branding ────────────────────────────────────────────────────────
  Widget _logoAndBrandingSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 15.h),
      _sectionLabel('Logo'),
      SizedBox(height: 6.h),
      _imgBox(
        picked: _logoPicked,
        placeholderAsset: 'assets/home_control/image.svg',
        pickIconAsset: 'assets/control/camera.svg',
        onPick: () async {
          final p = await _pickImage(allowRaster: true); // BUG-68
          if (p != null) setState(() => _logoPicked = p);
        },
      ),
      if (_submitted && _logoPicked.isEmpty)
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            'Logo image is required (SVG, PNG, JPG or WebP)',
            style:
                StyleText.fontSize12Weight400.copyWith(color: ColorPick.red),
          ),
        ),
      SizedBox(height: 14.h),
      Row(children: [
        Expanded(child: _ColorPickerField(
            controller: _primaryColor,
            label: 'Primary Color',
            hintText: '#008037',
            onColorChanged: () => setState(() {}))),
        SizedBox(width: 16.w),
        Expanded(child: _ColorPickerField(
            controller: _secondaryColor,
            label: 'Secondary', // Figma (Editing Main Details)
            hintText: '#D9D9D9',
            onColorChanged: () => setState(() {}))),
      ]),
      SizedBox(height: 14.h),
      Row(children: [
        Expanded(child: _ColorPickerField(
            controller: _bgColor,
            label: 'Background',
            hintText: '#D9D9D9',
            onColorChanged: () => setState(() {}))),
        SizedBox(width: 16.w),
        Expanded(child: _ColorPickerField(
            controller: _headerFooterColor,
            label: 'Header and Footer',
            hintText: '#D9D9D9',
            onColorChanged: () => setState(() {}))),
      ]),
      SizedBox(height: 14.h),
      Row(children: [
        Expanded(child: _ColorPickerField(
            controller: _mainWidgetColor,
            label: 'Main Widget Color',
            hintText: '#D9D9D9',
            onColorChanged: () => setState(() {}))),
        SizedBox(width: 16.w),
        const Expanded(child: SizedBox()),
      ]),
      SizedBox(height: 14.h),
      Row(children: [
        Expanded(child: CustomDropdown<String>(
          label: 'English Font',
          hint: 'Select font',
          value: _engFont,
          items: _kFonts
              .map((m) => DropdownItem<String>(
                  value: m['key']!, label: m['value']!))
              .toList(),
          onChanged: (val) => setState(() => _engFont = val),
        )),
        SizedBox(width: 16.w),
        Expanded(child: CustomDropdown<String>(
          label: 'Arabic Font',
          hint: 'Select font',
          // BUG-78: Arabic-capable fonts only. A previously saved Latin font
          // is not in this list, so the field asks for a new choice.
          value: _kArabicFonts.any((m) => m['key'] == _arFont) ? _arFont : null,
          items: _kArabicFonts
              .map((m) => DropdownItem<String>(
                  value: m['key']!, label: m['value']!))
              .toList(),
          onChanged: (val) => setState(() => _arFont = val),
        )),
      ]),
    ],
  );

  // ─── Navigation Items section ───────────────────────────────────────────────
  Widget _navSection() {
    final isOpen = _open['navBtn'] ?? true;
    return CustomAccordion(
      title:    'Navigation Items',
      isOpen:   isOpen,
      onToggle: () => setState(() => _open['navBtn'] = !isOpen),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _navBtns.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final btn = _navBtns.removeAt(oldIndex);
                final route = _navRoutes.removeAt(oldIndex);
                final status = _navStatus.removeAt(oldIndex);
                _navBtns.insert(newIndex, btn);
                _navRoutes.insert(newIndex, route);
                _navStatus.insert(newIndex, status);
              });
            },
            itemBuilder: (context, i) =>
                _buildNavItemRow(key: ValueKey('nav_$i'), index: i),
          ),
      ]),
    );
  }

  Widget _buildNavItemRow({required Key key, required int index}) {
    final nameEnCtrl = _navBtns[index]['nameEn']!;
    final nameArCtrl = _navBtns[index]['nameAr']!;

    // Fixed page identity (not editable) — shown as the field label so the
    // admin always knows which page this item is, whatever they rename it to.
    final String pageLabel = switch (_navRoutes[index]) {
      '/'         => 'Home',
      '/services' => 'Services',
      '/about'    => 'About Us',
      '/contact'  => 'Contact Us',
      '/careers'  => 'Careers',
      _           => 'Title',
    };

    return Padding(
      key: key,
      padding: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15.h),
            Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 27.h),
                child: ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8.h, right: 8.w),
                    child: Icon(Icons.menu_rounded,
                        size: 20.sp, color: AppColors.secondaryText),
                  ),
                ),
              ),
              Expanded(
                child: CustomTextField(
                  label: pageLabel,
                  // Status switch pinned to the END of the first field so it
                  // always lines up regardless of screen width.
                  labelTrailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Status ',
                          style: StyleText.fontSize12Weight500
                              .copyWith(color: AppColors.text)),
                      FlutterSwitch(
                        width: 35.sp,
                        height: 20.sp,
                        padding: 3.sp,
                        borderRadius: 20.sp,
                        toggleSize: 16.sp,
                        activeColor: ColorPick.primary,
                        inactiveColor: Colors.grey.withValues(alpha: .16),
                        value: _navStatus[index],
                        onToggle: (val) {
                          setState(() => _navStatus[index] = val);
                        },
                      ),
                    ],
                  ),
                  required: true,
                  fillColor: Colors.white,
                  hint: 'Home',
                  controller: nameEnCtrl,
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
                    label: 'عنصر التنقل',
                    required: true,
                    fillColor: Colors.white,
                    hint: 'الرئيسية',
                    controller: nameArCtrl,
                    height: 36,
                    submitted: _submitted,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Footer ─────────────────────────────────────────────────────────────────
  Widget _footerSection(MainCmsCubit cubit) => _accordion(
    key: 'footer',
    title: 'Footer',
    children: [
      ...List.generate(
          _footerColumns.length, (i) => _buildFooterColumn(i)),
      GestureDetector(
        onTap: () => setState(() => _footerColumns.add(_newFooterColumn())),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
              color: const Color(0xFF797979),
              borderRadius: BorderRadius.circular(4.r)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add, size: 14.sp, color: Colors.white),
            SizedBox(width: 4.w),
            Text('Column',
                style: StyleText.fontSize12Weight500
                    .copyWith(color: Colors.white)),
          ]),
        ),
      ),
    ],
  );
}
