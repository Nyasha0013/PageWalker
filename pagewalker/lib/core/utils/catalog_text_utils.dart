String sanitizeCatalogTitle(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return s;
  // strip MARC $a / $b junk from some feeds
  s = s.replaceAll(RegExp(r'\$[a-z0-9]\s*'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

/// Strip HTML from catalog descriptions and split into readable paragraphs.
List<String> formatBookDescriptionParagraphs(String? raw) {
  var s = (raw ?? '').trim();
  if (s.isEmpty) return const [];

  s = s
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  final chunks = s
      .split(RegExp(r'\n{2,}'))
      .map((part) => part.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (chunks.length > 1) return chunks;

  final single = chunks.isNotEmpty ? chunks.first : s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (single.isEmpty) return const [];
  if (single.length <= 320) return [single];

  return single
      .split(RegExp(r'(?<=[.!?])\s+(?=[A-Z"“])'))
      .map((part) => part.trim())
      .where((part) => part.length > 20)
      .take(8)
      .toList();
}
