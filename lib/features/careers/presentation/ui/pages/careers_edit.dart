// ******************* FILE INFO *******************
// File Name: careers_edit.dart
// Created by: Amr Mesbah
// Screen: 1.2 — Edit form for Careers Overview + Career Statistics
// FIXED: SVG bytes are uploaded to Firebase Storage → iconUrl saved to Firestore
// UPDATED: Publish button disabled on validation errors / empty fields
// UPDATED: After confirm dialog → navigates to CareersMainPageMaster
// UPDATED: Pattern matches ServicesMainEditPage (BlocConsumer, _hasChanges, _isFormValid)
// UPDATED: Removed loading overlay and spinner from Publish button
// FIXED: Preview button navigates to preview page correctly (flag prevents
//        BlocConsumer from intercepting the save and redirecting to main page)

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:web_app_admin/core/widget/success_toast.dart';

import 'package:web_app_admin/core/widget/network_image_view.dart';
import '../../../../../core/constant/color.dart';
import '../../../../../core/custom/image_upload_circle.dart';
import '../../../../../core/custom_dialog.dart';
import '../../../../../core/custom_svg.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/edit_action_buttons.dart';
import '../../../../../core/main_widgets/app_admin_navbar.dart';
import '../../../../../core/theme/appcolors.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../../core/custom/2-custom_textfield.dart';
import '../../../../job/presentation/ui/pages/job_listing_main.dart';
import '../../../../main/presentation/ui/pages/main_main.dart';
import '../../../data/models/careers_model.dart';
import '../../controller/careers_cubit.dart';
import '../../controller/careers_state.dart';
import 'careers_main.dart'; // CareersMainPageDashboard
import 'careers_main_page.dart'; // CareersMainPageMaster lives here
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';

part '../widgets/careers_edit/careers_edit_widgets.dart';



// class _C {
//   static const Color primary   = Color(0xFF008037);
//   static const Color labelText = Color(0xFF333333);
//   static const Color red       = Color(0xFFD32F2F);
//   static const Color grey      = Color(0xFF9E9E9E);
//   static const Color back      = Color(0xFFF1F2ED);
// }

class CareersEditPage extends StatefulWidget {
  const CareersEditPage({super.key});
  @override
  State<CareersEditPage> createState() => _CareersEditPageState();
}

class _CareersEditPageState extends State<CareersEditPage> {
  late CareersCmsModel _draft;

  late TextEditingController _overviewDescEnCtrl;
  late TextEditingController _overviewDescArCtrl;
  late TextEditingController _overviewBtnEnCtrl;
  late TextEditingController _overviewBtnArCtrl;

  final Map<String, Map<String, TextEditingController>> _statCtrls = {};
  final Map<String, bool> _open = {'overview': true, 'statistics': true};

  bool _ready              = false;
  bool _submitted          = false;
  bool _hasChanges         = false;
  bool _isSaving           = false;

  /// When true the BlocConsumer listener will navigate to preview instead of
  /// CareersMainPageMaster after a successful cubit save.
  bool _navigatingToPreview = false;

  // ── Icon tracking ──────────────────────────────────────────────────────────
  final Map<String, Uint8List?> _statIcons    = {};
  final Map<String, String>     _statIconUrls = {};

  // ── Original values for change detection ──────────────────────────────────
  String _originalDescEn = '';
  String _originalDescAr = '';
  String _originalBtnEn  = '';
  String _originalBtnAr  = '';

  // ────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final s = context.read<CareersCmsCubit>().state;
    if (s is CareersCmsLoaded || s is CareersCmsSaved) {
      _initFromModel(context.read<CareersCmsCubit>().current);
      _ready = true;
    } else {
      context.read<CareersCmsCubit>().load().then((_) {
        if (mounted) {
          setState(() {
            _initFromModel(context.read<CareersCmsCubit>().current);
            _ready = true;
          });
        }
      });
    }
  }

  void _initFromModel(CareersCmsModel model) {
    _draft = model;

    _originalDescEn = model.overview.description.en;
    _originalDescAr = model.overview.description.ar;
    _originalBtnEn  = model.overview.actionButtonLabel.en;
    _originalBtnAr  = model.overview.actionButtonLabel.ar;

    _overviewDescEnCtrl = TextEditingController(text: _originalDescEn);
    _overviewDescArCtrl = TextEditingController(text: _originalDescAr);
    _overviewBtnEnCtrl  = TextEditingController(text: _originalBtnEn);
    _overviewBtnArCtrl  = TextEditingController(text: _originalBtnAr);

    _overviewDescEnCtrl.addListener(_checkForChanges);
    _overviewDescArCtrl.addListener(_checkForChanges);
    _overviewBtnEnCtrl.addListener(_checkForChanges);
    _overviewBtnArCtrl.addListener(_checkForChanges);

    for (final s in model.statistics) {
      _initStatCtrl(s);
      _statIcons[s.id]    = null;
      _statIconUrls[s.id] = s.iconUrl;
    }
    _originalStatsSig = _statsSignature;
  }

  // BUG-62: statistics were invisible to the change check — adding, removing
  // or editing a statistic never counted as a change, so Publish stayed
  // disabled with a misleading message. Everything the statistics section
  // owns is now part of the comparison.
  String _originalStatsSig = '';

  String get _statsSignature => _draft.statistics.map((s) {
        final m = _statCtrls[s.id];
        final t = m == null
            ? ''
            : '${m['titleEn']!.text}|${m['titleAr']!.text}|'
                '${m['shortDescEn']!.text}|${m['shortDescAr']!.text}';
        return '${s.id}#$t#${_statIconUrls[s.id] ?? ''}';
      }).join('~');

  void _initStatCtrl(CareerStatItem s) {
    _statCtrls[s.id] = {
      'titleEn':     TextEditingController(text: s.title.en),
      'titleAr':     TextEditingController(text: s.title.ar),
      'shortDescEn': TextEditingController(text: s.shortDescription.en),
      'shortDescAr': TextEditingController(text: s.shortDescription.ar),
    };
    for (final c in _statCtrls[s.id]!.values) {
      c.addListener(_checkForChanges);
    }
  }

  // ── Change detection ───────────────────────────────────────────────────────
  void _checkForChanges() {
    final bool hasChanges =
        _overviewDescEnCtrl.text != _originalDescEn ||
            _overviewDescArCtrl.text != _originalDescAr ||
            _overviewBtnEnCtrl.text  != _originalBtnEn  ||
            _overviewBtnArCtrl.text  != _originalBtnAr  ||
            _statIcons.values.any((v) => v != null) ||
            _statsSignature != _originalStatsSig; // BUG-62

    // BUG-62: ALWAYS rebuild. Publish validity (_isFormValid) is computed in
    // build(); with the old "only when _hasChanges flips" check, typing into a
    // newly added Statistic never rebuilt the page, so Publish stayed grey
    // ("Please fix validation errors…") although every field was filled.
    if (mounted) setState(() => _hasChanges = hasChanges);
  }

  @override
  void dispose() {
    if (_ready) {
      _overviewDescEnCtrl.removeListener(_checkForChanges);
      _overviewDescArCtrl.removeListener(_checkForChanges);
      _overviewBtnEnCtrl.removeListener(_checkForChanges);
      _overviewBtnArCtrl.removeListener(_checkForChanges);

      _overviewDescEnCtrl.dispose();
      _overviewDescArCtrl.dispose();
      _overviewBtnEnCtrl.dispose();
      _overviewBtnArCtrl.dispose();

      for (final m in _statCtrls.values) {
        for (final c in m.values) {
          c.removeListener(_checkForChanges);
          c.dispose();
        }
      }
    }
    super.dispose();
  }

  // ── SVG-only file picker ───────────────────────────────────────────────────
  Future<Uint8List?> _pickSvgFile() async {
    final completer = Completer<Uint8List?>();
    final input = html.FileUploadInputElement()
      ..accept = '.svg,image/svg+xml';

    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }
      final file = files.first;
      if (!file.name.toLowerCase().endsWith('.svg')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only SVG files are allowed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        completer.complete(null);
        return;
      }
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) {
        if (reader.readyState == html.FileReader.DONE) {
          final result = reader.result;
          if (result is ByteBuffer) {
            completer.complete(result.asUint8List());
          } else if (result is Uint8List) {
            completer.complete(result);
          } else {
            completer.complete(null);
          }
        }
      });
      reader.onError.listen((_) => completer.complete(null));
    });

    input.click();
    return completer.future;
  }

  // ── Upload SVG bytes → Firebase Storage → returns download URL ─────────────
  Future<String> _uploadSvgToStorage({
    required String statId,
    required Uint8List bytes,
  }) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('careers/statistics/$statId/icon.svg');

    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/svg+xml'),
    );
    final url = await task.ref.getDownloadURL();
    return url;
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  bool get _isFormValid {
    if (_overviewDescEnCtrl.text.trim().isEmpty) return false;
    if (_overviewDescArCtrl.text.trim().isEmpty) return false;
    if (_overviewBtnEnCtrl.text.trim().isEmpty)  return false;
    if (_overviewBtnArCtrl.text.trim().isEmpty)  return false;

    for (final stat in _draft.statistics) {
      final ctrls = _statCtrls[stat.id];
      if (ctrls == null) continue;
      if (ctrls['titleEn']!.text.trim().isEmpty)     return false;
      if (ctrls['titleAr']!.text.trim().isEmpty)     return false;
      if (ctrls['shortDescEn']!.text.trim().isEmpty) return false;
      if (ctrls['shortDescAr']!.text.trim().isEmpty) return false;
    }
    return true;
  }

  bool get _isPublishEnabled => _hasChanges && !_isSaving && _isFormValid;

  String get _publishTooltip {
    if (_isSaving)     return '';
    if (!_hasChanges)  return 'No changes to publish';
    if (!_isFormValid) return 'Please fix validation errors before publishing';
    return '';
  }

  // ── Upload any new icons, then build model with all iconUrls ───────────────
  Future<CareersCmsModel> _buildDraftWithUploads() async {
    for (final stat in _draft.statistics) {
      final newBytes = _statIcons[stat.id];
      if (newBytes != null) {
        final url = await _uploadSvgToStorage(
          statId: stat.id,
          bytes: newBytes,
        );
        _statIconUrls[stat.id] = url;
        _statIcons[stat.id]    = null; // consumed — avoid re-upload
      }
    }

    return _draft.copyWith(
      overview: CareersOverview(
        description: BilingualText(
            en: _overviewDescEnCtrl.text.trim(),
            ar: _overviewDescArCtrl.text.trim()),
        actionButtonLabel: BilingualText(
            en: _overviewBtnEnCtrl.text.trim(),
            ar: _overviewBtnArCtrl.text.trim()),
      ),
      statistics: _draft.statistics.map((s) {
        final m = _statCtrls[s.id];
        if (m == null) return s;
        return s.copyWith(
          title: BilingualText(
              en: m['titleEn']!.text.trim(),
              ar: m['titleAr']!.text.trim()),
          shortDescription: BilingualText(
              en: m['shortDescEn']!.text.trim(),
              ar: m['shortDescAr']!.text.trim()),
          iconUrl: _statIconUrls[s.id] ?? s.iconUrl,
        );
      }).toList(),
    );
  }

  // ── Add / remove stat ──────────────────────────────────────────────────────
  void _addStat() {
    final newStat = CareerStatItem.empty();
    setState(() {
      _draft = _draft.copyWith(statistics: [..._draft.statistics, newStat]);
      _initStatCtrl(newStat);
      _statIcons[newStat.id]    = null;
      _statIconUrls[newStat.id] = '';
    });
    _checkForChanges(); // BUG-62
  }

  void _removeStat(String id) {
    setState(() {
      _draft = _draft.copyWith(
          statistics: _draft.statistics.where((s) => s.id != id).toList());
      final m = _statCtrls.remove(id);
      if (m != null) {
        for (final c in m.values) {
          c.removeListener(_checkForChanges);
          c.dispose();
        }
      }
      _statIcons.remove(id);
      _statIconUrls.remove(id);
    });
    _checkForChanges(); // BUG-62
  }

  // ── Publish: save to Firestore → BlocConsumer navigates to main page ────────
  Future<void> _performSave() async {
    if (!mounted) return;
    _navigatingToPreview = false; // explicit: this is a publish, not preview
    setState(() => _isSaving = true);
    try {
      final model = await _buildDraftWithUploads();
      await context.read<CareersCmsCubit>().save(model);
      // BlocConsumer listener handles navigation on CareersCmsSaved
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handlePublish() async {
    setState(() => _submitted = true);
    if (!_isFormValid) return;

    await showPublishConfirmDialog(
      context: context,
      title: 'PUBLISH CAREERS PAGE',
      subtitle: 'Do you want to publish the changes made to this Careers page?',
      confirmLabel: 'Publish',
      backLabel: 'Back',
      onConfirm: _performSave,
    );
  }

  // ── Preview: upload icons, save to cubit, then push preview route ───────────
  //
  // The key problem: BlocConsumer listens for CareersCmsSaved and normally
  // pushAndRemoveUntil → CareersMainPageMaster.  We set _navigatingToPreview=true
  // BEFORE calling save so the listener knows to pushNamed('careers-cms-preview')
  // instead of replacing the stack.
  Future<void> _preview() async {
    // Mark intent BEFORE the async gap so the listener sees it synchronously
    // when the saved state arrives.
    _navigatingToPreview = true;
    setState(() => _submitted = true);

    try {
      final model = await _buildDraftWithUploads();
      await context.read<CareersCmsCubit>().save(model);
      // Navigation is handled by BlocConsumer listener below
    } catch (e) {
      // Reset flag so future publishes still navigate to main page
      _navigatingToPreview = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load preview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _discard() {
    if (_hasChanges) {
      confirmDiscard(context, onDiscard: () => Navigator.pop(context));
    } else {
      Navigator.pop(context);
    }
  }

  // ── Loading shell ──────────────────────────────────────────────────────────
  // Same layout as the real page (navbar, sub navbar, title) with a spinner in
  // place of the form — avoids the blank grey screen between pages.
  Widget _loadingScaffold() {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: AdminStickyBody(
  guardUnsavedChanges: true, // BUG-267
          children: [
            AppAdminNavbar(
              activeLabel:    'Web Page',
              homePage:       CareersMainPageDashboard(),
              webPage:        MainMainPage(),
              jobListingPage: JobListingMainPage(),
            ),
            SizedBox(height: 20.h),
            AdminSubNavBar(activeIndex: 5),
            Container(
              width:   1000.w,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editing Careers Details',
                    style: StyleText.fontSize45Weight600.copyWith(
                        color:      ColorPick.primary,
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    height: 320.h,
                    width:  double.infinity,
                    child:  const Center(child: CircleProgress()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // The page chrome (navbar + sub navbar + title) is rendered right away so
    // the edit screen opens directly; only the form area shows a spinner while
    // the data is still being fetched.
    if (!_ready) {
      return _loadingScaffold();
    }

    return BlocConsumer<CareersCmsCubit, CareersCmsState>(
      listener: (context, state) {
        if (state is CareersCmsSaved) {
          // Defer navigation OUT of the frame (fixes mouse_tracker
          // !_debugDuringDeviceUpdate assertion on Flutter web debug).
          Future.delayed(Duration.zero, () {
            if (!mounted) return;

            if (_navigatingToPreview) {
              // ── Preview path ─────────────────────────────────────────────
              // Push preview on top of the edit page so the user can come back.
              _navigatingToPreview = false; // reset for any subsequent publish
              context.pushNamed('careers-cms-preview');
            } else {
              // ── Publish path ─────────────────────────────────────────────
              // BUG-276: go to the VIEW URL (a pushed MaterialPageRoute left
              // the address on /admin/careers-cms/edit).
              showSuccessToast(context, 'Careers page published'); // BUG-293
              context.go('/admin/careers-cms');
            }
          });
        }

        if (state is CareersCmsError) {
          _navigatingToPreview = false; // reset on error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SizedBox(
            width: double.infinity,
            child: AdminStickyBody(
  guardUnsavedChanges: true, // BUG-267
  children: [
                  AppAdminNavbar(
                    activeLabel:    'Web Page',
                    homePage:       CareersMainPageDashboard(),
                    webPage:        MainMainPage(),
                    jobListingPage: JobListingMainPage(),
                  ),
                  SizedBox(height: 20.h),
                  AdminSubNavBar(activeIndex: 5),
                  Container(
                    width:   1000.w,
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editing Careers Details',
                          style: StyleText.fontSize45Weight600.copyWith(
                              color:      ColorPick.primary,
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 20.h),

                        // ── Careers Overview ───────────────────────────
                        _accordion(
                          key:   'overview',
                          title: 'Careers Overview',
                          children: [
                            SizedBox(height: 15.h),
                            _enField(
                              label: 'Description', hint: 'Text Here',
                              ctrl: _overviewDescEnCtrl,
                              height: 80, maxLines: 4,
                            ),
                            SizedBox(height: 10.h),
                            _arField(
                              label: 'الوصف', hint: 'أكتب هنا',
                              ctrl: _overviewDescArCtrl,
                              height: 80, maxLines: 4,
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _enField(
                                    label: 'Action Button',
                                    hint:  'Text Here',
                                    ctrl:  _overviewBtnEnCtrl,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: _arField(
                                    label: 'زر الإجراء',
                                    hint:  'أدخل النص',
                                    ctrl:  _overviewBtnArCtrl,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),

                        // ── Career Statistics ──────────────────────────
                        _accordion(
                          key:   'statistics',
                          title: 'Career Statistics',
                          children: [
                            SizedBox(height: 15.h),
                            ..._draft.statistics.asMap().entries.map((e) {
                              final i    = e.key;
                              final stat = e.value;
                              final m    = _statCtrls[stat.id]!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (i > 0) SizedBox(height: 12.h),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${_ord(i + 1)} Statistics',
                                          style: StyleText.fontSize16Weight600
                                              .copyWith(color: AppColors.text)),
                                      GestureDetector(
                                        onTap: () => _removeStat(stat.id),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color:        Colors.red,
                                            borderRadius: BorderRadius.circular(4.r),
                                          ),
                                          child: Text('Remove',
                                              style: StyleText.fontSize12Weight500
                                                  .copyWith(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _enField(
                                          // BUG-72: the title is free text
                                          // (e.g. "25+" or "MENA"); nothing
                                          // blocks Publish silently any more.
                                          label: 'Title', hint: 'e.g. 25+',
                                          ctrl: m['titleEn']!,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: _arField(
                                          label: 'العنوان', hint: 'مثال: +25',
                                          ctrl: m['titleAr']!,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  _enField(
                                    label: 'Short Description', hint: 'Text Here',
                                    ctrl: m['shortDescEn']!, height: 60, maxLines: 3,
                                  ),
                                  SizedBox(height: 8.h),
                                  _arField(
                                    label: 'وصف مختصر', hint: 'أكتب هنا',
                                    ctrl: m['shortDescAr']!, height: 60, maxLines: 3,
                                  ),
                                  SizedBox(height: 12.h),
                                ],
                              );
                            }),

                            GestureDetector(
                              onTap: _addStat,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14.w, vertical: 7.h),
                                decoration: BoxDecoration(
                                  color:        const Color(0xFF797979),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 14.sp, color: Colors.white),
                                    SizedBox(width: 4.w),
                                    Text('Statistics',
                                        style: StyleText.fontSize12Weight500
                                            .copyWith(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        _actionButtons(),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ],
),
          ),
        );
      },
    );
  }
  }