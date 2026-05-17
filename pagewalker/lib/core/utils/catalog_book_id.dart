bool isUnifiedCatalogBookId(String id) {
  return id.startsWith('google_') ||
      id.startsWith('gutenberg_') ||
      id.startsWith('openlibrary_');
}
