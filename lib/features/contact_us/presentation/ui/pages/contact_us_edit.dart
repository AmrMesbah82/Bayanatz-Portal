// ******************* FILE INFO *******************
// File Name: contact_us_edit.dart
// Created by: Claude Assistant
// UPDATED: Social icon "Insert Links" replaced with dropdown from footer social links
// UPDATED: Publish button now shows confirmation dialog with validation
// UPDATED: Fixed race condition — seed deferred until both Home & Contact CMS are loaded

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:web_app_admin/core/theme/appcolors.dart';

import 'package:web_app_admin/core/widget/textfield.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';

import '../../../../../core/constant/color.dart';
import '../../../../../core/custom/1-custom_dropdwon.dart';
import '../../../../../core/custom/image_upload_circle.dart';
import '../../../../../core/custom_dialog.dart';
import '../../../../../core/custom_svg.dart';
import '../../../../../core/main_widgets/admin_sticky_body.dart';
import '../../../../../core/main_widgets/admin_sub_navbar.dart';
import '../../../../../core/main_widgets/edit_action_buttons.dart';
import '../../../../../core/theme/new_theme.dart';
import '../../../../../core/theme/text.dart';
import '../../../../home/data/models/home_model.dart';
import '../../../../main/presentation/controller/main_cubit.dart';
import '../../../../main/presentation/controller/main_state.dart';
import '../../../data/models/contact_us_model_location.dart';
import '../../controller/contact_us_location_cubit.dart';
import '../../controller/contact_us_location_state.dart';
import 'contact_us_preview.dart';
import '../../../../../core/custom/3-custom_accordion.dart';
import 'package:web_app_admin/core/custom/circle_progress.dart';
import 'package:web_app_admin/core/main_widgets/app_admin_navbar.dart';
import 'package:web_app_admin/features/careers/presentation/ui/pages/careers_main.dart';
import 'package:web_app_admin/features/main/presentation/ui/pages/main_main.dart';
import 'package:web_app_admin/features/job/presentation/ui/pages/job_listing_main.dart';

part '../widgets/contact_us_edit/social_link_dropdown.dart';
part '../widgets/contact_us_edit/social_icon_item.dart';
part '../widgets/contact_us_edit/office_location_item.dart';
part '../widgets/contact_us_edit/contact_us_edit_ui.dart';

// const Color ColorPick.primary      = Color(0xFF2D8C4E);
// const Color ColorPick.primary = Color(0xFF008037);
// const Color ColorPick.primaryLight = Color(0xFFE8F5EE);
// const Color ColorPick.red        = Color(0xFFD32F2F);
// const Color _kSurface    = Color(0xFFFFFFFF);
// const Color _kBg         = Color(0xFFF2F2F2);

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ContactUsCmsEditPage extends StatefulWidget {
  const ContactUsCmsEditPage({super.key});

  @override
  State<ContactUsCmsEditPage> createState() => _ContactUsCmsEditPageState();
}

class _ContactUsCmsEditPageState extends State<ContactUsCmsEditPage> {
  // ── Info section ──
  final _subDescEnCtrl = TextEditingController();
  final _subDescArCtrl = TextEditingController();
  final _emailCtrl     = TextEditingController();

  // ── Social Icons (Follow Us) ──
  final List<_SocialIconItem> _socialIconItems = [];
  int _socialIconCounter = 0;

  // ── Office Locations ──
  final List<_OfficeLocationItem> _officeLocationItems = [];
  int _officeLocationCounter = 0;

  // ── Confirm Message ──
  final _confirmTitleEnCtrl = TextEditingController();
  final _confirmTitleArCtrl = TextEditingController();
  final _confirmDescEnCtrl  = TextEditingController();
  final _confirmDescArCtrl  = TextEditingController();
  Uint8List? _confirmSvgBytes;
  String     _confirmSvgUrl = '';

  // ── Accordion open/close ──
  bool _infoOpen    = true;
  bool _officesOpen = true;
  bool _confirmOpen = true;

  bool _submitted = false;
  bool _seeded    = false;
  bool _isSaving  = false;

  // ── Footer social links (loaded from MainCmsCubit) ──
  List<SocialLinkModel> _footerSocialLinks = [];

  // ── Deferred seed: wait for BOTH cubits ──
  ContactUsCmsModel? _pendingModel;
  final _followTitleEnCtrl = TextEditingController();
  final _followTitleArCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    context.read<ContactUsCmsCubit>().load();
    // Load Home CMS to get footer social links
    context.read<MainCmsCubit>().load();
  }

  @override
  void dispose() {
    _subDescEnCtrl.dispose();
    _subDescArCtrl.dispose();
    _emailCtrl.dispose();
    _followTitleEnCtrl.dispose();
    _followTitleArCtrl.dispose();
    _confirmTitleEnCtrl.dispose();
    _confirmTitleArCtrl.dispose();
    _confirmDescEnCtrl.dispose();
    _confirmDescArCtrl.dispose();
    for (final o in _officeLocationItems) {
      o.locationNameEnCtrl.dispose();
      o.locationNameArCtrl.dispose();
      o.text1EnCtrl.dispose();
      o.text1ArCtrl.dispose();
      o.text2EnCtrl.dispose();
      o.text2ArCtrl.dispose();
      o.mapLinkCtrl.dispose();
    }
    super.dispose();
  }

  // ── Try seed — only runs when BOTH footer links AND CMS model are ready ──

  void _trySeed() {
    if (_seeded) return;
    if (_pendingModel == null || _footerSocialLinks.isEmpty) return;
    _seeded = true;
    _seedFromModel(_pendingModel!);
  }

  // ── Seed from loaded model ────────────────────────────────────────────────

  void _seedFromModel(ContactUsCmsModel m) {
    _subDescEnCtrl.text = m.subDescription.en;
    _subDescArCtrl.text = m.subDescription.ar;
    _emailCtrl.text     = m.email;

    // Social icons — AUTO-FILLED from the MAIN page social links
    // (edit_sections2 → MainCmsCubit). No manual selection.
    _autoFillSocialIcons(m);

    // Office locations
    _officeLocationItems.clear();
    for (final o in m.officeLocations) {
      final item = _OfficeLocationItem(
        id:      o.id,
        counter: ++_officeLocationCounter,
      );
      item.locationNameEnCtrl.text = o.locationName.en;
      item.locationNameArCtrl.text = o.locationName.ar;
      item.text1EnCtrl.text        = o.text1.en;
      item.text1ArCtrl.text        = o.text1.ar;
      item.text2EnCtrl.text        = o.text2.en;
      item.text2ArCtrl.text        = o.text2.ar;
      item.mapLinkCtrl.text        = o.mapLink;
      item.iconUrl                 = o.iconUrl;
      _officeLocationItems.add(item);
    }

    // Confirm message
    _confirmTitleEnCtrl.text = m.confirmMessage.title.en;
    _confirmTitleArCtrl.text = m.confirmMessage.title.ar;
    _confirmDescEnCtrl.text  = m.confirmMessage.description.en;
    _confirmDescArCtrl.text  = m.confirmMessage.description.ar;
    _confirmSvgUrl           = m.confirmMessage.svgUrl;
  }

  // ── Image pickers ─────────────────────────────────────────────────────────

  Future<Uint8List?> _pickImage({bool allowSvg = false}) async {
    final completer = Completer<Uint8List?>();
    final input = html.FileUploadInputElement()
      ..accept = allowSvg ? 'image/*,.svg' : 'image/*';

    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }
      final file   = files.first;
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

  Future<Uint8List?> _pickSvgFile() async {
    final completer = Completer<Uint8List?>();
    final input = html.FileUploadInputElement();

    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }
      final file     = files.first;
      final fileName = file.name.toLowerCase();
      if (!fileName.endsWith('.svg')) {
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

  // ── Preview ───────────────────────────────────────────────────────────────

  /// BUG-52 / BUG-53: Preview used `context.goNamed(...)`, which REPLACED the
  /// edit page (unsaved edits lost, Back had nothing to return to → white
  /// screen) and the preview re-read the PUBLISHED document. Now the preview
  /// is pushed on top of the form with the current draft, so Back returns to
  /// the form with every change still in place.
  void _openDraftPreview() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ContactUsCmsPreviewPage(draft: _buildModel('draft')),
    ));
  }

  // ── Build model ───────────────────────────────────────────────────────────

  ContactUsCmsModel _buildModel(String status) {
    return ContactUsCmsModel(
      publishStatus: status,
      subDescription: ContactBilingualText(
        en: _subDescEnCtrl.text.trim(),
        ar: _subDescArCtrl.text.trim(),
      ),
      email: _emailCtrl.text.trim(),
      followUsTitle: ContactBilingualText(
        en: _followTitleEnCtrl.text.trim(),
        ar: _followTitleArCtrl.text.trim(),
      ),
      socialIcons: _socialIconItems
          .map((s) {
        // Resolve index → URL safely
        final url = (s.selectedIndex != null &&
            s.selectedIndex! < _footerSocialLinks.length)
            ? _footerSocialLinks[s.selectedIndex!].url
            : '';
        return ContactSocialIcon(
          id:      s.id,
          iconUrl: s.iconUrl,
          link:    url,
        );
      })
          .toList(),
      officeLocations: _officeLocationItems
          .map((o) => ContactOfficeLocation(
        id:      o.id,
        iconUrl: o.iconUrl,
        mapLink: o.mapLinkCtrl.text.trim(),
        locationName: ContactBilingualText(
          en: o.locationNameEnCtrl.text.trim(),
          ar: o.locationNameArCtrl.text.trim(),
        ),
        text1: ContactBilingualText(
          en: o.text1EnCtrl.text.trim(),
          ar: o.text1ArCtrl.text.trim(),
        ),
        text2: ContactBilingualText(
          en: o.text2EnCtrl.text.trim(),
          ar: o.text2ArCtrl.text.trim(),
        ),
      ))
          .toList(),
      confirmMessage: ContactConfirmMessage(
        svgUrl: _confirmSvgUrl,
        title: ContactBilingualText(
          en: _confirmTitleEnCtrl.text.trim(),
          ar: _confirmTitleArCtrl.text.trim(),
        ),
        description: ContactBilingualText(
          en: _confirmDescEnCtrl.text.trim(),
          ar: _confirmDescArCtrl.text.trim(),
        ),
      ),
    );
  }

  // ── Collect uploads ───────────────────────────────────────────────────────

  Map<String, Uint8List> _collectUploads() {
    final uploads = <String, Uint8List>{};
    for (final s in _socialIconItems) {
      if (s.iconBytes != null) {
        uploads['contact_cms/social_icons/${s.id}/icon'] = s.iconBytes!;
      }
    }
    for (final o in _officeLocationItems) {
      if (o.iconBytes != null) {
        uploads['contact_cms/office_locations/${o.id}/icon'] = o.iconBytes!;
      }
    }
    if (_confirmSvgBytes != null) {
      uploads['contact_cms/confirm_message/svg'] = _confirmSvgBytes!;
    }
    return uploads;
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool _validateAllFields() {
    final requiredCtrls = [
      _subDescEnCtrl,
      _subDescArCtrl,
      _emailCtrl,
      _confirmTitleEnCtrl,
      _confirmTitleArCtrl,
      _confirmDescEnCtrl,
      _confirmDescArCtrl,
      for (final o in _officeLocationItems) ...[
        o.locationNameEnCtrl,
        o.locationNameArCtrl,
        o.text1EnCtrl,
        o.text1ArCtrl,
      ],
    ];

    return !requiredCtrls.any((c) => c.text.trim().isEmpty);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save(String status) async {
    setState(() => _submitted = true);

    if (!_validateAllFields()) return;

    setState(() => _isSaving = true);
    final model   = _buildModel(status);
    final uploads = _collectUploads();
    await context.read<ContactUsCmsCubit>().save(
      model:        model,
      imageUploads: uploads.isEmpty ? null : uploads,
    );
    setState(() => _isSaving = false);
  }

  // ── Publish with confirmation dialog ──────────────────────────────────────

  Future<void> _handlePublish() async {
    // First validate all fields
    setState(() => _submitted = true);

    if (!_validateAllFields()) {
      // If validation fails, scroll to top so user can see errors
      return;
    }

    // Show confirmation dialog
    await showPublishConfirmDialog(
      context: context,
      title: 'PUBLISH CONTACT US PAGE',
      subtitle: 'Do you want to publish the changes made to this Contact Us page?',
      confirmLabel: 'Publish',
      backLabel: 'Back',
      onConfirm: () => _save('published'),
    );
  }

  // ── Social icons auto-fill ────────────────────────────────────────────────
  // One item per MAIN social link that has a URL. The link is fixed (index
  // into _footerSocialLinks); the saved contact icon is matched back by URL.
  void _autoFillSocialIcons(ContactUsCmsModel? m) {
    _socialIconItems.clear();
    for (var i = 0; i < _footerSocialLinks.length; i++) {
      final link = _footerSocialLinks[i];
      if (link.url.isEmpty) continue;

      // Reuse the previously saved contact icon for this link, if any.
      final saved = m?.socialIcons
          .where((s) => s.link == link.url)
          .toList();
      final item = _SocialIconItem(
        id: (saved != null && saved.isNotEmpty) ? saved.first.id : 'social_$i',
        counter: ++_socialIconCounter,
      );
      item.selectedIndex = i;
      item.iconUrl = (saved != null && saved.isNotEmpty)
          ? saved.first.iconUrl
          : link.iconUrl;
      _socialIconItems.add(item);
    }
  }

  void _addOfficeLocation() {
    setState(() {
      _officeLocationItems.add(
        _OfficeLocationItem(
          id:      'office_${DateTime.now().millisecondsSinceEpoch}',
          counter: ++_officeLocationCounter,
        ),
      );
    });
  }

  void _removeOfficeLocation(String id) =>
      setState(() => _officeLocationItems.removeWhere((o) => o.id == id));

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ── Listen to MainCmsCubit to get footer social links ──
        BlocListener<MainCmsCubit, MainCmsState>(
          listener: (context, homeState) {
            final links = switch (homeState) {
              MainCmsLoaded(:final data) => data.socialLinks,
              MainCmsSaved(:final data)  => data.socialLinks,
              _                          => <SocialLinkModel>[],
            };
            if (links.isNotEmpty) {
              setState(() {
                _footerSocialLinks = links;
                _trySeed();
                // Keep the auto-filled icons in sync when Main links change
                // after the initial seed.
                if (_seeded) _autoFillSocialIcons(_pendingModel);
              });
            }
          },
        ),
        // ── Listen to ContactUsCmsCubit ──
        BlocListener<ContactUsCmsCubit, ContactUsCmsState>(
          listener: (context, state) {
            if (state is ContactUsCmsLoaded) {
              setState(() {
                _pendingModel = state.data;
                _trySeed();
              });
            }
            if (state is ContactUsCmsSaved) {
              setState(() => _isSaving = false);
            }
            if (state is ContactUsCmsError) {
              setState(() => _isSaving = false);
            }
          },
        ),
      ],
      child: BlocBuilder<ContactUsCmsCubit, ContactUsCmsState>(
        builder: (context, state) {
          final isLoading =
              state is ContactUsCmsLoading || state is ContactUsCmsInitial;

          return Scaffold(
            backgroundColor:  Color(0xFFF1F2ED),
            body: Stack(
              children: [
                AdminStickyBody(
  contentWidth: 1000.w,
  children: [
                              AppAdminNavbar(
                                activeLabel:    'Web Page',
                                homePage:       CareersMainPageDashboard(),
                                webPage:        MainMainPage(),
                                jobListingPage: JobListingMainPage(),
                              ),
                              SizedBox(height: 25.h),
                              AdminSubNavBar(activeIndex: 4),
                              SizedBox(
                                width: 1000.w,
                                child: isLoading
                                    ? const Center(
                                  child: CircleProgress(),
                                )
                                    : _buildForm(),
                              ),
                            ],
),
                if (_isSaving) _buildSavingOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }
}
