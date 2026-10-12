// ******************* FILE INFO *******************
// File Name: site_preview_sources.dart
// Description: Where a preview gets the draft it should render.
//
//              Each accessor pulls the model currently being edited out of its
//              admin cubit, whatever state that cubit happens to be in, and
//              falls back to the cubit's in-memory model so a preview never
//              goes blank mid-save or after a transient error.
//
//              `context.watch` is deliberate: previews re-render on every
//              keystroke in the edit screen, so what you see is always the
//              unsaved draft.
//
// Created by: Amr Mesbah

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/main/data/models/main_model.dart';
import '../../features/main/presentation/controller/main_cubit.dart';

/// The Main-page draft — branding colors, logo, footer columns, social links
/// and the site navbar items. Every preview needs it, because the site shell
/// wraps every page.
MainPageModel draftMainModel(BuildContext context) {
  final MainCmsCubit cubit = context.watch<MainCmsCubit>();

  // BUG-53: the cubit's in-memory model holds the edits being made (the
  // editor copies them in before opening Preview); state.data is the
  // snapshot taken when the page was LOADED, i.e. the published text.
  return cubit.current;
}
