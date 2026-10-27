// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Art Explorer';

  @override
  String get tabDiscover => 'Upptäck';

  @override
  String get tabSearch => 'Sök';

  @override
  String get tabBookmarks => 'Bokmärken';

  @override
  String get tabSettings => 'Inställningar';

  @override
  String get offlineBanner => 'Du är offline. Visar endast sparat innehåll.';

  @override
  String get retry => 'Försök igen';

  @override
  String get cancel => 'Avbryt';

  @override
  String get save => 'Spara';

  @override
  String get clear => 'Rensa';

  @override
  String get reset => 'Återställ';

  @override
  String get apply => 'Använd';

  @override
  String get more => 'Mer';

  @override
  String get searchTitle => 'Sök';

  @override
  String get searchHint => 'Konstnärer, motiv, riktningar…';

  @override
  String get filters => 'Filter';

  @override
  String get recent => 'Senaste';

  @override
  String get trySearching => 'Prova att söka efter';

  @override
  String resultsCount(int count) {
    return '$count resultat';
  }

  @override
  String worksCount(int count) {
    return '$count verk';
  }

  @override
  String get noArtworkFound => 'Inga konstverk hittades';

  @override
  String get noArtworkFoundHint => 'Prova en annan sökning eller färre filter.';

  @override
  String get noWorksFound => 'Inga verk hittades';

  @override
  String get noWorksFoundHint =>
      'Det finns inga digitaliserade verk av den här konstnären.';

  @override
  String get endOfResults => 'Slut på resultaten';

  @override
  String filterYear(int from, int to) {
    return 'År: $from – $to';
  }

  @override
  String get country => 'Land';

  @override
  String get anyCountry => 'Alla länder';

  @override
  String get openLicenseOnly => 'Endast öppna licenser';

  @override
  String get openLicenseHint => 'Public domain och Creative Commons';

  @override
  String get read => 'Läs';

  @override
  String get view => 'Visa';

  @override
  String get source => 'Källa';

  @override
  String get bookmark => 'Bokmärk';

  @override
  String get removeBookmark => 'Ta bort bokmärke';

  @override
  String get bookmarked => 'Bokmärkt';

  @override
  String get share => 'Dela';

  @override
  String get savedToBookmarks => 'Sparad i bokmärken';

  @override
  String get removedBookmark => 'Bokmärket togs bort';

  @override
  String get moreLikeThis => 'Mer som detta';

  @override
  String get rightsAttribution => 'Rättigheter och erkännande';

  @override
  String providedBy(String provider) {
    return 'Tillhandahållen av $provider via Europeana';
  }

  @override
  String get couldNotLoadDetails => 'Det gick inte att läsa in alla detaljer.';

  @override
  String get couldNotOpenLink => 'Det gick inte att öppna länken';

  @override
  String get medium => 'Teknik';

  @override
  String get dimensions => 'Mått';

  @override
  String get place => 'Plats';

  @override
  String get readMoreWikipedia => 'Läs mer på Wikipedia';

  @override
  String get noBiography => 'Ingen biografi tillgänglig.';

  @override
  String get reader => 'Läsläge';

  @override
  String get readAloud => 'Läs upp';

  @override
  String get stopReading => 'Sluta läsa upp';

  @override
  String get readAloudUnavailable => 'Uppläsning är inte tillgänglig';

  @override
  String get readingSettings => 'Läsinställningar';

  @override
  String get background => 'Bakgrund';

  @override
  String fontSize(int size) {
    return 'Textstorlek: $size';
  }

  @override
  String get font => 'Typsnitt';

  @override
  String lineSpacing(String value) {
    return 'Radavstånd: $value';
  }

  @override
  String margins(int value) {
    return 'Marginaler: $value';
  }

  @override
  String get noDescription =>
      'Ingen skriven beskrivning finns för det här verket.';

  @override
  String get themePaper => 'Papper';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get themeNight => 'Natt';

  @override
  String backgroundLabel(String name) {
    return 'Bakgrund: $name';
  }

  @override
  String get aboutThisWork => 'Om verket';

  @override
  String get aboutTheArtist => 'Om konstnären';

  @override
  String get subjects => 'Motiv';

  @override
  String get bookmarksTitle => 'Bokmärken';

  @override
  String get noBookmarks => 'Inga bokmärken ännu';

  @override
  String get noBookmarksHint =>
      'Tryck på bokmärkesikonen på ett konstverk för att spara det här.';

  @override
  String get searchBookmarks => 'Sök i bokmärken';

  @override
  String get noMatchingBookmarks => 'Inga matchande bokmärken';

  @override
  String get all => 'Alla';

  @override
  String get sortNewest => 'Nyaste först';

  @override
  String get sortOldest => 'Äldsta först';

  @override
  String get sortTitle => 'Titel A–Ö';

  @override
  String get sort => 'Sortera';

  @override
  String get listView => 'Listvy';

  @override
  String get gridView => 'Rutnätsvy';

  @override
  String get addToCollection => 'Lägg till i samling';

  @override
  String get newCollection => 'Ny samling';

  @override
  String get removeFromCollection => 'Ta bort från samling';

  @override
  String get bookmarkRemoved => 'Bokmärket togs bort';

  @override
  String get undo => 'Ångra';

  @override
  String get discoverTitle => 'Upptäck';

  @override
  String get surpriseMe => 'Överraska mig';

  @override
  String get surpriseFailed => 'Kunde inte hitta en överraskning. Försök igen.';

  @override
  String get artworkOfTheDay => 'Dagens konstverk';

  @override
  String get retryArtworkOfTheDay => 'Försök igen med dagens konstverk';

  @override
  String get pickUp => 'Fortsätt där du slutade';

  @override
  String get movements => 'Konstriktningar';

  @override
  String get themes => 'Teman';

  @override
  String get byCentury => 'Efter århundrade';

  @override
  String get byCountry => 'Efter land';

  @override
  String moreTopic(String topic) {
    return 'Mer: $topic';
  }

  @override
  String artOfCentury(String century) {
    return 'Konst från $century';
  }

  @override
  String get exploreFooter =>
      'Bilder och metadata via Europeana. Rättigheter varierar per verk; raderna här visar verk med öppna licenser.';

  @override
  String get settingsTitle => 'Inställningar';

  @override
  String get appearance => 'Utseende';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get light => 'Ljust';

  @override
  String get dark => 'Mörkt';

  @override
  String get language => 'Språk';

  @override
  String get readerSection => 'Läsläge';

  @override
  String get defaultReadingStyle => 'Standardutseende för läsning';

  @override
  String get defaultReadingStyleHint =>
      'Bakgrund, typsnitt, storlek och avstånd';

  @override
  String get sources => 'Källor';

  @override
  String get enabled => 'Aktiverad';

  @override
  String get data => 'Data';

  @override
  String get clearHistory => 'Rensa visningshistorik';

  @override
  String get historyCleared => 'Historiken rensades';

  @override
  String get clearImageCache => 'Rensa bildcache';

  @override
  String get imageCacheCleared => 'Bildcachen rensades';

  @override
  String get about => 'Om appen';

  @override
  String get aboutBody =>
      'Konstverkens metadata och bilder kommer från Europeana och dess dataleverantörer. Varje verk visar sitt eget rättighetsutlåtande. Biografier kommer från Wikipedia (CC BY-SA).';

  @override
  String get licensesHint => 'Tryck ovan för att se öppen källkod-licenser.';

  @override
  String get errNetwork =>
      'Ingen anslutning. Kontrollera nätverket och försök igen.';

  @override
  String get errRateLimit =>
      'För många förfrågningar. Vänta en stund och försök igen.';

  @override
  String get errNotFound => 'Inget hittades.';

  @override
  String get errParse => 'Servern skickade data som vi inte kunde läsa.';

  @override
  String get errUnknown => 'Något gick fel. Försök igen.';

  @override
  String factBy(String names) {
    return 'Av $names.';
  }

  @override
  String factDated(String date) {
    return 'Daterad $date.';
  }

  @override
  String factMedium(String value) {
    return 'Teknik: $value.';
  }

  @override
  String factDimensions(String value) {
    return 'Mått: $value.';
  }

  @override
  String factPlace(String value) {
    return 'Plats: $value.';
  }

  @override
  String descriptionFrom(String provider) {
    return 'Beskrivning från $provider';
  }

  @override
  String zoomableImage(String title) {
    return 'Zoombar bild av $title';
  }

  @override
  String openFullScreen(String title) {
    return 'Öppna bilden i helskärm: $title';
  }

  @override
  String get languageSystem => 'Systemstandard';
}
