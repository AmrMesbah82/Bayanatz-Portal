part of '../../pages/main_preview.dart';

// The fake browser viewport used to live here as `_PreviewContent`.
//
// It now lives in core/site_preview/site_shell_preview.dart as the public
// `SiteShellPreview`, for two reasons:
//
//   1. The `package:website_app/...` imports it needs can only live in a real
//      library, not in a `part` file. While they sat in main_preview.dart and
//      were referenced only from here, "Optimize Imports" deleted them as
//      unused on every save and broke the build.
//   2. Every other admin preview page (about_us, careers, services, …) needs
//      the same site shell, so it belongs in core/ rather than under main/.
//
// This file is intentionally left empty. Delete it once you are happy the
// preview works — the `part` directive in main_preview.dart goes with it.
