/// A themed starting point for exploring without typing a query.
class ExploreTopic {
  const ExploreTopic(this.title, this.query);
  final String title;
  final String query;
}

const movements = [
  ExploreTopic('Impressionism', 'impressionism'),
  ExploreTopic('Baroque', 'baroque'),
  ExploreTopic('Renaissance', 'renaissance'),
  ExploreTopic('Art Nouveau', 'art nouveau'),
  ExploreTopic('Romanticism', 'romanticism'),
  ExploreTopic('Cubism', 'cubism'),
  ExploreTopic('Ukiyo-e', 'ukiyo-e'),
  ExploreTopic('Symbolism', 'symbolism'),
];

const themes = [
  ExploreTopic('Landscapes', 'landscape'),
  ExploreTopic('Portraits', 'portrait'),
  ExploreTopic('Still life', 'still life'),
  ExploreTopic('Seascapes', 'seascape'),
  ExploreTopic('Mythology', 'mythology'),
  ExploreTopic('Flowers', 'flowers'),
  ExploreTopic('Animals', 'animals'),
  ExploreTopic('Sculpture', 'sculpture'),
];

class Century {
  const Century(this.label, this.from, this.to);
  final String label;
  final int from;
  final int to;
}

const centuries = [
  Century('1400s', 1400, 1499),
  Century('1500s', 1500, 1599),
  Century('1600s', 1600, 1699),
  Century('1700s', 1700, 1799),
  Century('1800s', 1800, 1899),
  Century('1900s', 1900, 1999),
];

const browseCountries = [
  'France',
  'Netherlands',
  'Italy',
  'Spain',
  'Germany',
  'Sweden',
  'Denmark',
  'Poland',
];

/// Deterministic daily index so "Artwork of the day" is stable for a date.
int dayOfYearSeed(DateTime date) =>
    date.year * 1000 + date.difference(DateTime(date.year)).inDays;

/// Picks the topic for a given day.
ExploreTopic topicOfTheDay(DateTime date) {
  final all = [...movements, ...themes];
  return all[dayOfYearSeed(date) % all.length];
}
