class RelativeTimeFormatter {
  const RelativeTimeFormatter._();

  static String vi(DateTime value) {
    final now = DateTime.now();
    final localValue = value.isUtc ? value.toLocal() : value;
    final diff = now.difference(localValue);

    if (diff.inSeconds < 45) {
      return 'vừa xong';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }

    if (diff.inDays == 1) {
      return 'hôm qua';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }

    return '${localValue.day.toString().padLeft(2, '0')}/'
        '${localValue.month.toString().padLeft(2, '0')}/'
        '${localValue.year}';
  }
}
