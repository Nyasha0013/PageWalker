String? fixCoverUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  return url
      .trim()
      .replaceAll('http://', 'https://')
      .replaceAll('zoom=1', 'zoom=3');
}

String? httpsCoverUrl(String? url) => fixCoverUrl(url);
