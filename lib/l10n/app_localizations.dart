import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sv'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Art Explorer'**
  String get appTitle;

  /// No description provided for @tabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get tabDiscover;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get tabBookmarks;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing saved content only.'**
  String get offlineBanner;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Artists, subjects, movements…'**
  String get searchHint;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @trySearching.
  ///
  /// In en, this message translates to:
  /// **'Try searching for'**
  String get trySearching;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCount(int count);

  /// No description provided for @worksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} works'**
  String worksCount(int count);

  /// No description provided for @noArtworkFound.
  ///
  /// In en, this message translates to:
  /// **'No artwork found'**
  String get noArtworkFound;

  /// No description provided for @noArtworkFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or fewer filters.'**
  String get noArtworkFoundHint;

  /// No description provided for @noWorksFound.
  ///
  /// In en, this message translates to:
  /// **'No works found'**
  String get noWorksFound;

  /// No description provided for @noWorksFoundHint.
  ///
  /// In en, this message translates to:
  /// **'There are no digitised works for this creator.'**
  String get noWorksFoundHint;

  /// No description provided for @endOfResults.
  ///
  /// In en, this message translates to:
  /// **'End of results'**
  String get endOfResults;

  /// No description provided for @filterYear.
  ///
  /// In en, this message translates to:
  /// **'Year: {from} – {to}'**
  String filterYear(int from, int to);

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @anyCountry.
  ///
  /// In en, this message translates to:
  /// **'Any country'**
  String get anyCountry;

  /// No description provided for @openLicenseOnly.
  ///
  /// In en, this message translates to:
  /// **'Openly licensed only'**
  String get openLicenseOnly;

  /// No description provided for @openLicenseHint.
  ///
  /// In en, this message translates to:
  /// **'Public domain and Creative Commons'**
  String get openLicenseHint;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get removeBookmark;

  /// No description provided for @bookmarked.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get bookmarked;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @savedToBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Saved to bookmarks'**
  String get savedToBookmarks;

  /// No description provided for @removedBookmark.
  ///
  /// In en, this message translates to:
  /// **'Removed bookmark'**
  String get removedBookmark;

  /// No description provided for @moreLikeThis.
  ///
  /// In en, this message translates to:
  /// **'More like this'**
  String get moreLikeThis;

  /// No description provided for @rightsAttribution.
  ///
  /// In en, this message translates to:
  /// **'Rights & attribution'**
  String get rightsAttribution;

  /// No description provided for @providedBy.
  ///
  /// In en, this message translates to:
  /// **'Provided by {provider} via Europeana'**
  String providedBy(String provider);

  /// No description provided for @couldNotLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load full details.'**
  String get couldNotLoadDetails;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get couldNotOpenLink;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @dimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get dimensions;

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get place;

  /// No description provided for @readMoreWikipedia.
  ///
  /// In en, this message translates to:
  /// **'Read more on Wikipedia'**
  String get readMoreWikipedia;

  /// No description provided for @noBiography.
  ///
  /// In en, this message translates to:
  /// **'No biography available.'**
  String get noBiography;

  /// No description provided for @reader.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get reader;

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// No description provided for @stopReading.
  ///
  /// In en, this message translates to:
  /// **'Stop reading aloud'**
  String get stopReading;

  /// No description provided for @readAloudUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Read-aloud is not available'**
  String get readAloudUnavailable;

  /// No description provided for @readingSettings.
  ///
  /// In en, this message translates to:
  /// **'Reading settings'**
  String get readingSettings;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size: {size}'**
  String fontSize(int size);

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @lineSpacing.
  ///
  /// In en, this message translates to:
  /// **'Line spacing: {value}'**
  String lineSpacing(String value);

  /// No description provided for @margins.
  ///
  /// In en, this message translates to:
  /// **'Margins: {value}'**
  String margins(int value);

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No written description is available for this work.'**
  String get noDescription;

  /// No description provided for @themePaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get themePaper;

  /// No description provided for @themeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get themeSepia;

  /// No description provided for @themeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get themeNight;

  /// No description provided for @backgroundLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} background'**
  String backgroundLabel(String name);

  /// No description provided for @aboutThisWork.
  ///
  /// In en, this message translates to:
  /// **'About this work'**
  String get aboutThisWork;

  /// No description provided for @aboutTheArtist.
  ///
  /// In en, this message translates to:
  /// **'About the artist'**
  String get aboutTheArtist;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @bookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarksTitle;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarks;

  /// No description provided for @noBookmarksHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon on any artwork to save it here.'**
  String get noBookmarksHint;

  /// No description provided for @searchBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Search bookmarks'**
  String get searchBookmarks;

  /// No description provided for @noMatchingBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No matching bookmarks'**
  String get noMatchingBookmarks;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldest;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title A–Z'**
  String get sortTitle;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get sortRelevance;

  /// No description provided for @sortMostComplete.
  ///
  /// In en, this message translates to:
  /// **'Most complete records'**
  String get sortMostComplete;

  /// No description provided for @sortRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get sortRecentlyAdded;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get gridView;

  /// No description provided for @addToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get addToCollection;

  /// No description provided for @newCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get newCollection;

  /// No description provided for @removeFromCollection.
  ///
  /// In en, this message translates to:
  /// **'Remove from collection'**
  String get removeFromCollection;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @surpriseMe.
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get surpriseMe;

  /// No description provided for @surpriseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not find a surprise. Try again.'**
  String get surpriseFailed;

  /// No description provided for @artworkOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Artwork of the day'**
  String get artworkOfTheDay;

  /// No description provided for @retryArtworkOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Retry artwork of the day'**
  String get retryArtworkOfTheDay;

  /// No description provided for @pickUp.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get pickUp;

  /// No description provided for @byCentury.
  ///
  /// In en, this message translates to:
  /// **'By century'**
  String get byCentury;

  /// No description provided for @byCountry.
  ///
  /// In en, this message translates to:
  /// **'By country'**
  String get byCountry;

  /// No description provided for @moreTopic.
  ///
  /// In en, this message translates to:
  /// **'More {topic}'**
  String moreTopic(String topic);

  /// No description provided for @artOfCentury.
  ///
  /// In en, this message translates to:
  /// **'Art of the {century}'**
  String artOfCentury(String century);

  /// No description provided for @exploreFooter.
  ///
  /// In en, this message translates to:
  /// **'Images and metadata via Europeana. Rights vary by item; rows here show openly licensed works.'**
  String get exploreFooter;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @readerSection.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get readerSection;

  /// No description provided for @defaultReadingStyle.
  ///
  /// In en, this message translates to:
  /// **'Default reading style'**
  String get defaultReadingStyle;

  /// No description provided for @defaultReadingStyleHint.
  ///
  /// In en, this message translates to:
  /// **'Background, font, size and spacing'**
  String get defaultReadingStyleHint;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear viewing history'**
  String get clearHistory;

  /// No description provided for @historyCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get historyCleared;

  /// No description provided for @clearImageCache.
  ///
  /// In en, this message translates to:
  /// **'Clear image cache'**
  String get clearImageCache;

  /// No description provided for @imageCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Image cache cleared'**
  String get imageCacheCleared;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Artwork metadata and images come from Europeana and its data providers. Each item shows its own rights statement. Biographies come from Wikipedia (CC BY-SA).'**
  String get aboutBody;

  /// No description provided for @licensesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap above to view open-source licenses.'**
  String get licensesHint;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and retry.'**
  String get errNetwork;

  /// No description provided for @errRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and retry.'**
  String get errRateLimit;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found.'**
  String get errNotFound;

  /// No description provided for @errParse.
  ///
  /// In en, this message translates to:
  /// **'The server sent data we could not read.'**
  String get errParse;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please retry.'**
  String get errUnknown;

  /// No description provided for @factBy.
  ///
  /// In en, this message translates to:
  /// **'By {names}.'**
  String factBy(String names);

  /// No description provided for @factDated.
  ///
  /// In en, this message translates to:
  /// **'Dated {date}.'**
  String factDated(String date);

  /// No description provided for @factMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium: {value}.'**
  String factMedium(String value);

  /// No description provided for @factDimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions: {value}.'**
  String factDimensions(String value);

  /// No description provided for @factPlace.
  ///
  /// In en, this message translates to:
  /// **'Place: {value}.'**
  String factPlace(String value);

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @showOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get showOriginal;

  /// No description provided for @translating.
  ///
  /// In en, this message translates to:
  /// **'Translating…'**
  String get translating;

  /// No description provided for @machineTranslated.
  ///
  /// In en, this message translates to:
  /// **'Machine translated'**
  String get machineTranslated;

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t translate. Check your connection and try again.'**
  String get translationFailed;

  /// No description provided for @previousArtwork.
  ///
  /// In en, this message translates to:
  /// **'Previous artwork'**
  String get previousArtwork;

  /// No description provided for @nextArtwork.
  ///
  /// In en, this message translates to:
  /// **'Next artwork'**
  String get nextArtwork;

  /// No description provided for @descriptionFrom.
  ///
  /// In en, this message translates to:
  /// **'Description from {provider}'**
  String descriptionFrom(String provider);

  /// No description provided for @zoomableImage.
  ///
  /// In en, this message translates to:
  /// **'Zoomable image of {title}'**
  String zoomableImage(String title);

  /// No description provided for @openFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Open full screen image of {title}'**
  String openFullScreen(String title);

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @searchWithin.
  ///
  /// In en, this message translates to:
  /// **'Search in {title}'**
  String searchWithin(String title);

  /// No description provided for @browseSubjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects & techniques'**
  String get browseSubjects;

  /// No description provided for @browseMuseums.
  ///
  /// In en, this message translates to:
  /// **'Museums & collections'**
  String get browseMuseums;

  /// No description provided for @browsePeriods.
  ///
  /// In en, this message translates to:
  /// **'Time periods'**
  String get browsePeriods;

  /// No description provided for @browseCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get browseCountries;

  /// No description provided for @browseColours.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get browseColours;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @filterList.
  ///
  /// In en, this message translates to:
  /// **'Filter list'**
  String get filterList;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @allOfPeriod.
  ///
  /// In en, this message translates to:
  /// **'All of {period}'**
  String allOfPeriod(String period);

  /// No description provided for @colourTitle.
  ///
  /// In en, this message translates to:
  /// **'Colour {hex}'**
  String colourTitle(String hex);

  /// No description provided for @decadeLabel.
  ///
  /// In en, this message translates to:
  /// **'{year}s'**
  String decadeLabel(String year);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
