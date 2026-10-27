import 'package:codedbykay_art_explorer/core/result.dart';
import 'package:codedbykay_art_explorer/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// User-facing text for a [Failure] in the current language.
String failureText(AppLocalizations l, Failure failure) => switch (failure) {
  NetworkFailure() => l.errNetwork,
  RateLimitFailure() => l.errRateLimit,
  NotFoundFailure() => l.errNotFound,
  ParseFailure() => l.errParse,
  UnknownFailure() => l.errUnknown,
};
