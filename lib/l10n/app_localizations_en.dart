// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Art Explorer';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabBookmarks => 'Bookmarks';

  @override
  String get tabSettings => 'Settings';

  @override
  String get offlineBanner => 'You\'re offline. Showing saved content only.';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get clear => 'Clear';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get more => 'More';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Artists, subjects, movements…';

  @override
  String get filters => 'Filters';

  @override
  String get recent => 'Recent';

  @override
  String get trySearching => 'Try searching for';

  @override
  String resultsCount(int count) {
    return '$count results';
  }

  @override
  String worksCount(int count) {
    return '$count works';
  }

  @override
  String get noArtworkFound => 'No artwork found';

  @override
  String get noArtworkFoundHint => 'Try a different search or fewer filters.';

  @override
  String get noWorksFound => 'No works found';

  @override
  String get noWorksFoundHint =>
      'There are no digitised works for this creator.';

  @override
  String get endOfResults => 'End of results';

  @override
  String filterYear(int from, int to) {
    return 'Year: $from – $to';
  }

  @override
  String get country => 'Country';

  @override
  String get anyCountry => 'Any country';

  @override
  String get openLicenseOnly => 'Openly licensed only';

  @override
  String get openLicenseHint => 'Public domain and Creative Commons';

  @override
  String get read => 'Read';

  @override
  String get view => 'View';

  @override
  String get source => 'Source';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get removeBookmark => 'Remove bookmark';

  @override
  String get bookmarked => 'Bookmarked';

  @override
  String get share => 'Share';

  @override
  String get savedToBookmarks => 'Saved to bookmarks';

  @override
  String get removedBookmark => 'Removed bookmark';

  @override
  String get moreLikeThis => 'More like this';

  @override
  String get rightsAttribution => 'Rights & attribution';

  @override
  String providedBy(String provider) {
    return 'Provided by $provider via Europeana';
  }

  @override
  String get couldNotLoadDetails => 'Could not load full details.';

  @override
  String get couldNotOpenLink => 'Could not open the link';

  @override
  String get medium => 'Medium';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get place => 'Place';

  @override
  String get readMoreWikipedia => 'Read more on Wikipedia';

  @override
  String get noBiography => 'No biography available.';

  @override
  String get reader => 'Reader';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get stopReading => 'Stop reading aloud';

  @override
  String get readAloudUnavailable => 'Read-aloud is not available';

  @override
  String get readingSettings => 'Reading settings';

  @override
  String get background => 'Background';

  @override
  String fontSize(int size) {
    return 'Font size: $size';
  }

  @override
  String get font => 'Font';

  @override
  String lineSpacing(String value) {
    return 'Line spacing: $value';
  }

  @override
  String margins(int value) {
    return 'Margins: $value';
  }

  @override
  String get noDescription =>
      'No written description is available for this work.';

  @override
  String get themePaper => 'Paper';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get themeNight => 'Night';

  @override
  String backgroundLabel(String name) {
    return '$name background';
  }

  @override
  String get aboutThisWork => 'About this work';

  @override
  String get aboutTheArtist => 'About the artist';

  @override
  String get subjects => 'Subjects';

  @override
  String get bookmarksTitle => 'Bookmarks';

  @override
  String get noBookmarks => 'No bookmarks yet';

  @override
  String get noBookmarksHint =>
      'Tap the bookmark icon on any artwork to save it here.';

  @override
  String get searchBookmarks => 'Search bookmarks';

  @override
  String get noMatchingBookmarks => 'No matching bookmarks';

  @override
  String get all => 'All';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortTitle => 'Title A–Z';

  @override
  String get sort => 'Sort';

  @override
  String get listView => 'List view';

  @override
  String get gridView => 'Grid view';

  @override
  String get addToCollection => 'Add to collection';

  @override
  String get newCollection => 'New collection';

  @override
  String get removeFromCollection => 'Remove from collection';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get undo => 'Undo';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get surpriseMe => 'Surprise me';

  @override
  String get surpriseFailed => 'Could not find a surprise. Try again.';

  @override
  String get artworkOfTheDay => 'Artwork of the day';

  @override
  String get retryArtworkOfTheDay => 'Retry artwork of the day';

  @override
  String get pickUp => 'Pick up where you left off';

  @override
  String get movements => 'Movements';

  @override
  String get themes => 'Themes';

  @override
  String get byCentury => 'By century';

  @override
  String get byCountry => 'By country';

  @override
  String moreTopic(String topic) {
    return 'More $topic';
  }

  @override
  String artOfCentury(String century) {
    return 'Art of the $century';
  }

  @override
  String get exploreFooter =>
      'Images and metadata via Europeana. Rights vary by item; rows here show openly licensed works.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemDefault => 'System default';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get readerSection => 'Reader';

  @override
  String get defaultReadingStyle => 'Default reading style';

  @override
  String get defaultReadingStyleHint => 'Background, font, size and spacing';

  @override
  String get sources => 'Sources';

  @override
  String get enabled => 'Enabled';

  @override
  String get data => 'Data';

  @override
  String get clearHistory => 'Clear viewing history';

  @override
  String get historyCleared => 'History cleared';

  @override
  String get clearImageCache => 'Clear image cache';

  @override
  String get imageCacheCleared => 'Image cache cleared';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'Artwork metadata and images come from Europeana and its data providers. Each item shows its own rights statement. Biographies come from Wikipedia (CC BY-SA).';

  @override
  String get licensesHint => 'Tap above to view open-source licenses.';

  @override
  String get errNetwork => 'No connection. Check your network and retry.';

  @override
  String get errRateLimit =>
      'Too many requests. Please wait a moment and retry.';

  @override
  String get errNotFound => 'Nothing found.';

  @override
  String get errParse => 'The server sent data we could not read.';

  @override
  String get errUnknown => 'Something went wrong. Please retry.';

  @override
  String factBy(String names) {
    return 'By $names.';
  }

  @override
  String factDated(String date) {
    return 'Dated $date.';
  }

  @override
  String factMedium(String value) {
    return 'Medium: $value.';
  }

  @override
  String factDimensions(String value) {
    return 'Dimensions: $value.';
  }

  @override
  String factPlace(String value) {
    return 'Place: $value.';
  }

  @override
  String descriptionFrom(String provider) {
    return 'Description from $provider';
  }

  @override
  String zoomableImage(String title) {
    return 'Zoomable image of $title';
  }

  @override
  String openFullScreen(String title) {
    return 'Open full screen image of $title';
  }

  @override
  String get languageSystem => 'System default';
}
