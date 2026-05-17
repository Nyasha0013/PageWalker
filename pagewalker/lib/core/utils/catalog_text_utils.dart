String sanitizeCatalogTitle(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return s;
  // strip MARC $a / $b junk from some feeds
  s = s.replaceAll(RegExp(r'\$[a-z0-9]\s*'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}
