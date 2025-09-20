String getResizedImageUrl(String originalUrl, int width) {
  if (originalUrl.isEmpty) {
    return '';
  }
  // Assuming the server supports a 'width' query parameter for resizing.
  // This is a common convention, but might need to be adjusted based on the actual server implementation.
  return '$originalUrl?width=$width';
}
