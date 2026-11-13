import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

extension PlanrL10n on BuildContext {
  /// Falls back to English when a widget is shown outside the localized app.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}
