/// Her language choices: (code, name in that language).
const octoLanguages = [
  ('en', 'English'),
  ('hi', 'हिन्दी'),
  ('es', 'Español'),
  ('fr', 'Français'),
  ('de', 'Deutsch'),
  ('pt', 'Português'),
  ('bn', 'বাংলা'),
  ('ur', 'اردو'),
  ('ta', 'தமிழ்'),
  ('zh', '中文'),
];

/// The name of a language code, or the code itself.
String languageName(String? code) {
  for (final (c, name) in octoLanguages) {
    if (c == code) return name;
  }
  return code ?? '';
}
