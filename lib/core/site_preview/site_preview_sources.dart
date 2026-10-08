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
import '../../features/main/presentation/controller/main_state.dart';

/// The Main-page draft — branding colors, logo, footer columns, social links
/// and the site navbar items. Every preview needs it, because the site shell
/// wraps every page.
MainPageModel draftMainModel(BuildContext context) {
  final MainCmsCubit cubit = context.watch<MainCmsCubit>();
  final MainCmsState state = cubit.state;

  if (state is MainCmsLoaded)     return state.data;
  if (state is MainCmsSaving)     return state.data;
  if (state is MainCmsSaved)      return state.data;
  if (state is MainCmsDraftSaved) return state.data;
  if (state is MainCmsError && state.lastData != null) return state.lastData!;
  return cubit.current;
}
