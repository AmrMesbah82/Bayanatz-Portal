part of '../../pages/careers_main_page.dart';

class _InternsTabBody extends StatefulWidget {
  @override
  State<_InternsTabBody> createState() => _InternsTabBodyState();
}

class _InternsTabBodyState extends State<_InternsTabBody> {
  bool   _isGrid     = true;
  String _search     = '';
  /// BUG-93: "Time Frame" filter (by joined date) from the flowchart.
  DateTimeRange? _timeFrame;
  final  _searchCtrl = TextEditingController();

  // ── "Our Interns" section header (icon + title) ─────────────────────────────
  final _headerTitleEnCtrl = TextEditingController();
  final _headerTitleArCtrl = TextEditingController();
  Uint8List? _headerIconBytes;
  String     _headerIconUrl = '';
  bool       _headerSeeded  = false;
  bool       _headerSaving  = false;
  bool       _headerEditMode = false; // view-only until "Edit Details" clicked
  bool       _headerOpen     = true;  // accordion open/closed

  @override
  void dispose() {
    _searchCtrl.dispose();
    _headerTitleEnCtrl.dispose();
    _headerTitleArCtrl.dispose();
    super.dispose();
  }

  // ── Seed header fields once from the loaded section ─────────────────────────
  void _seedHeader(CareersSectionModel data) {
    if (_headerSeeded) return;
    _headerSeeded = true;
    if (data.items.isNotEmpty) {
      final h = data.items.first;
      _headerTitleEnCtrl.text = h.title.en;
      _headerTitleArCtrl.text = h.title.ar;
      _headerIconUrl = h.iconUrl;
    }
  }

  // ── SVG-only picker for the header icon ─────────────────────────────────────
  void _pickHeaderIcon() {
    final input = html.FileUploadInputElement()
      ..accept = '.svg,image/svg+xml';
    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files.first;
      if (!file.name.toLowerCase().endsWith('.svg')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Only SVG files are allowed.'),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }
      final reader = html.FileReader()..readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        Uint8List? bytes;
        if (result is ByteBuffer) {
          bytes = result.asUint8List();
        } else if (result is Uint8List) {
          bytes = result;
        } else if (result is List<int>) {
          bytes = Uint8List.fromList(result);
        }
        if (bytes != null && mounted) {
          setState(() => _headerIconBytes = bytes);
        }
      });
    });
    input.click();
  }

  // ── Save header → 'ourInterns' section (item 0) ─────────────────────────────
  Future<void> _saveHeader(CareersSectionCubit sectionCubit) async {
    setState(() => _headerSaving = true);
    try {
      if (sectionCubit.current.items.isEmpty) sectionCubit.addItem();
      final id = sectionCubit.current.items.first.id;
      sectionCubit.updateTitle(id,
          en: _headerTitleEnCtrl.text.trim(),
          ar: _headerTitleArCtrl.text.trim());
      if (_headerIconBytes != null) {
        await sectionCubit.uploadIcon(id, _headerIconBytes!);
        _headerIconBytes = null;
      }
      await sectionCubit.save();
      _headerSeeded = false;   // re-seed from the reloaded model
      _headerEditMode = false; // back to view-only after a successful save
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Our Interns header saved'),
          backgroundColor: ColorPick.primary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _headerSaving = false);
    }
  }

  // ── Cancel edit → discard changes, revert to the saved section ──────────────
  void _cancelHeaderEdit() {
    final data = context.read<CareersSectionCubit>().current;
    _headerSeeded = false;
    _seedHeader(data); // repopulates controllers + iconUrl from the saved model
    setState(() {
      _headerIconBytes = null;
      _headerEditMode  = false;
    });
  }

  String _fmtHeaderDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  // ── "Our Interns" header — view-only, with an Edit Details toggle ───────────
  Widget _headerEditor() {
    return BlocBuilder<CareersSectionCubit, CareersSectionState>(
      builder: (context, secState) {
        final sectionCubit = context.read<CareersSectionCubit>();
        CareersSectionModel? data;
        if (secState is CareersSectionLoaded) data = secState.data;
        if (secState is CareersSectionSaved)  data = secState.data;
        if (data != null) _seedHeader(data);
        final model = data ?? sectionCubit.current;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Last Updated + Edit Details ─────────────────────────────────
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                      color: ColorPick.white,
                      borderRadius: BorderRadius.circular(4.r)),
                  child: Text(
                    model.lastUpdated != null
                        ? 'Last Updated On ${_fmtHeaderDate(model.lastUpdated!)}'
                        : 'Last Updated On —',
                    style: StyleText.fontSize13Weight500
                        .copyWith(color: ColorPick.primary),
                  ),
                ),
                const Spacer(),
                if (!_headerEditMode)
                  GestureDetector(
                    onTap: () => setState(() => _headerEditMode = true),
                    child: Container(
                      width: 130.w, height: 36.h,
                      decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(4.r)),
                      child: Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Edit Details',
                              style: StyleText.fontSize14Weight500
                                  .copyWith(color: Colors.black)),
                          SizedBox(width: 6.w),
                          CustomSvg(
                              assetPath: 'assets/control/edit_icon_pick.svg',
                              width: 20.w, height: 20.h,
                              fit: BoxFit.scaleDown, color: ColorPick.primary),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 14.h),

            // ── Accordion: Our Interns ──────────────────────────────────────
            CustomAccordion(
              title:    'Our Interns',
              isOpen:   _headerOpen,
              onToggle: () => setState(() => _headerOpen = !_headerOpen),
              child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: _headerEditMode
                          ? _headerEditContent(sectionCubit)
                          : _headerViewContent(model),
                    ),
            ),
            SizedBox(height: 16.h),
          ],
        );
      },
    );
  }

  // ── View-only content ───────────────────────────────────────────────────────
  Widget _headerViewContent(CareersSectionModel model) {
    final item = model.items.isNotEmpty ? model.items.first : null;
    final String iconUrl = item?.iconUrl ?? '';
    final String titleEn = item?.title.en ?? '';
    final String titleAr = item?.title.ar ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Icon',
            style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 6.h),
        NetworkImageView.circle(url: iconUrl, diameter: 60.w),
        SizedBox(height: 14.h),
        Row(children: [
          Expanded(child: _headerRoField('Title', titleEn)),
          SizedBox(width: 16.w),
          Expanded(child: _headerRoField('العنوان', titleAr, rtl: true)),
        ]),
      ],
    );
  }

  Widget _headerRoField(String label, String value, {bool rtl = false}) {
    final field = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
      SizedBox(height: 4.h),
      Container(
        width: double.infinity,
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(4.r)),
        child: Text(
          value.isEmpty ? (rtl ? 'أكتب هنا' : 'Text Here') : value,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          style: StyleText.fontSize12Weight400.copyWith(
              color: value.isEmpty ? AppColors.secondaryText : AppColors.text),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
    return rtl
        ? Directionality(textDirection: TextDirection.rtl, child: field)
        : field;
  }

  // ── Editable content (icon upload + title fields + Save / Cancel) ───────────
  Widget _headerEditContent(CareersSectionCubit sectionCubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Icon',
            style: StyleText.fontSize12Weight500.copyWith(color: AppColors.text)),
        SizedBox(height: 8.h),
        imageUploadCircleBare(
          bytes: _headerIconBytes,
          url:   _headerIconUrl,
          onTap: _pickHeaderIcon,
        ),
        SizedBox(height: 14.h),
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title',
                    style: StyleText.fontSize12Weight500
                        .copyWith(color: AppColors.text)),
                SizedBox(height: 4.h),
                _headerTitleField(
                    _headerTitleEnCtrl, 'Text Here', TextDirection.ltr),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text('العنوان',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: StyleText.fontSize12Weight500
                          .copyWith(

                          color: AppColors.text)),
                ),
                SizedBox(height: 4.h),
                _headerTitleField(
                    _headerTitleArCtrl, 'أدخل النص', TextDirection.rtl),
              ],
            ),
          ),
        ]),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _headerSaving ? null : _cancelHeaderEdit,
              child: Container(
                height: 36.h,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                    color: const Color(0xFF797979),
                    borderRadius: BorderRadius.circular(6.r)),
                child: Center(
                  child: Text('Cancel',
                      style: StyleText.fontSize13Weight500
                          .copyWith(color: Colors.white)),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: _headerSaving ? null : () => _saveHeader(sectionCubit),
              child: Container(
                height: 36.h,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                  color: _headerSaving
                      ? ColorPick.primary.withValues(alpha: 0.5)
                      : ColorPick.primary,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Center(
                  child: _headerSaving
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircleProgress())
                      : Text('Save',
                          style: StyleText.fontSize13Weight500
                              .copyWith(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerTitleField(
      TextEditingController c, String hint, TextDirection dir) {
    final field = Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      alignment: dir == TextDirection.rtl
          ? Alignment.centerRight
          : Alignment.centerLeft,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6.r)),
      child: CustomTextField(
        controller: c,
        hint: hint,
        textDirection: dir,
        textAlign:
            dir == TextDirection.rtl ? TextAlign.right : TextAlign.left,
        fillColor:  Colors.white,
        contentPadding: EdgeInsets.zero,
        hintStyle: StyleText.fontSize13Weight400
            .copyWith(color: AppColors.secondaryText),
        valueStyle:
            StyleText.fontSize13Weight400.copyWith(color: AppColors.text),
      ),
    );
    return Directionality(textDirection: dir, child: field);
  }

  List<InternModel> _filtered(List<InternModel> all) {
    var list = all;
    // BUG-93: joined between the two picked days (inclusive).
    final tf = _timeFrame;
    if (tf != null) {
      final from = DateTime(tf.start.year, tf.start.month, tf.start.day);
      final to = DateTime(tf.end.year, tf.end.month, tf.end.day, 23, 59, 59);
      list = list
          .where((i) =>
              i.joinedDate != null &&
              !i.joinedDate!.isBefore(from) &&
              !i.joinedDate!.isAfter(to))
          .toList();
    }
    if (_search.isEmpty) return list;
    final q = _search.toLowerCase();
    return list
        .where((i) =>
    i.fullName.toLowerCase().contains(q) ||
        i.position.toLowerCase().contains(q) ||
        i.degrees.toLowerCase().contains(q))
        .toList();
  }

  String _fmtDay(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InternCubit, InternState>(
      listener: (context, state) {
        if (state is InternError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${state.message}'),
            backgroundColor: Colors.red,
          ));
        }
      },
      builder: (context, state) {
        List<InternModel> interns = [];
        bool loading = false;

        if (state is InternLoading) loading = true;
        if (state is InternLoaded)  interns = state.interns;
        if (state is InternCreated) interns = state.interns;
        if (state is InternUpdated) interns = state.interns;
        if (state is InternDeleted) interns = state.interns;

        final cubit    = context.read<InternCubit>();
        final filtered = _filtered(interns);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── "Our Interns" section header editor (icon + title) ──────────
            _headerEditor(),

            Row(children: [
              Expanded(
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(6.r)),
                  child: Row(children: [
                    SizedBox(width: 12.w),
                    CustomSvg(assetPath: "assets/search.svg"),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _searchCtrl,
                        hint: 'Search',
                        hintStyle: StyleText.fontSize13Weight400.copyWith(color: AppColors.secondaryText),
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                        valueStyle: StyleText.fontSize13Weight400.copyWith(color: AppColors.text),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                  ]),
                ),
              ),
              SizedBox(width: 12.w),

              // ── BUG-93: Time Frame (flowchart 1:10051) ──
              GestureDetector(
                onTap: () async {
                  final picked =
                      await showAdminDateRangePicker(context, initial: _timeFrame);
                  if (picked != null) setState(() => _timeFrame = picked);
                },
                child: Container(
                  height: 40.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                      color: ColorPick.primary, borderRadius: BorderRadius.circular(6.r)),
                  child: Center(
                    child: Text(
                        _timeFrame == null
                            ? 'Time Frame'
                            : '${_fmtDay(_timeFrame!.start)} – ${_fmtDay(_timeFrame!.end)}',
                        style: StyleText.fontSize13Weight500.copyWith(color: Colors.white)),
                  ),
                ),
              ),
              if (_timeFrame != null)
                IconButton(
                  tooltip: 'Clear time frame',
                  icon: Icon(Icons.close, size: 16.sp, color: ColorPick.primary),
                  onPressed: () => setState(() => _timeFrame = null),
                ),
              SizedBox(width: 12.w),

              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                      value: cubit, child: const AddInternPage()),
                )),
                child: Container(
                  height: 40.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                      color: ColorPick.primary, borderRadius: BorderRadius.circular(6.r)),
                  child: Center(
                    child: Text('Add New Intern',
                        style: StyleText.fontSize13Weight500.copyWith(color: Colors.white)),
                  ),
                ),
              ),
            ]),
            SizedBox(height: 14.h),

            Row(
              children: [
                Container(

                  height: 32.sp,
                  decoration: BoxDecoration(
                      color: ColorPick.white, borderRadius: BorderRadius.circular(6.r)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.sp),
                    child: Row(
                      children: [

                        Text(
                          'Total Interns:',
                          style: StyleText.fontSize12Weight500
                              .copyWith(color: AppColors.secondaryText),
                        ),
                        Text(
                          '${filtered.length}',
                          style: StyleText.fontSize12Weight500
                              .copyWith(color: AppColors.text),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                customButtonWithImage(
                  title: 'Export',
                  function: () => showDialog(context: context,
                      builder: (_) => _InternExportDialog(interns: filtered)),
                  textStyle: StyleText.fontSize12Weight600
                      .copyWith(color: Colors.white),
                  height: 32.sp, space: 4.w, radius: 6,
                  color: ColorPick.primary, image: 'assets/images/export.svg',
                  widthImage: 14.sp, heightImage: 14.sp,
                  colorBorder: ColorPick.primary, svgColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                ),
                SizedBox(width: 8.w),
                customButtonWithImage(
                  title: '', function: () => setState(() => _isGrid = true),
                  textStyle: StyleText.fontSize12Weight400,
                  height: 32.sp, width: 32.sp, space: 0, radius: 6,
                  color: _isGrid ? ColorPick.primary : ColorPick.white,
                  image: 'assets/images/grid.svg',
                  widthImage: 16.sp, heightImage: 16.sp,
                  colorBorder: Colors.transparent,
                  svgColor: _isGrid ? Colors.white : AppColors.secondaryText,
                ),
                SizedBox(width: 8.w),
                customButtonWithImage(
                  title: '', function: () => setState(() => _isGrid = false),
                  textStyle: StyleText.fontSize12Weight400,
                  height: 32.sp, width: 32.sp, space: 0, radius: 6,
                  color: !_isGrid ? ColorPick.primary : ColorPick.white,
                  image: 'assets/images/table.svg',
                  widthImage: 16.sp, heightImage: 16.sp,
                  colorBorder: Colors.transparent,
                  svgColor: !_isGrid ? Colors.white : AppColors.secondaryText,
                ),
              ],
            ),
            SizedBox(height: 16.h),

            if (loading)
              const Center(child: CircleProgress())
            else if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(40.w),
                  child: _search.isEmpty
                      ? SvgPicture.asset(
                          'assets/images/null.svg',
                          width: 200.w,
                          height: 200.h,
                        )
                      : Text(
                          'No results for "$_search".',
                          style: StyleText.fontSize14Weight400
                              .copyWith(color: AppColors.secondaryText),
                          textAlign: TextAlign.center,
                        ),
                ),
              )
            else if (_isGrid)
                _GridView(interns: filtered, cubit: cubit)
              else
                _InternTableView(interns: filtered, cubit: cubit),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRID VIEW  (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════
