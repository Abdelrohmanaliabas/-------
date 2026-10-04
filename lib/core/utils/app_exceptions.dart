/// Base exception for application errors with friendly Arabic messages
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'تعذر الاتصال بالإنترنت، يرجى التحقق من الشبكة وإعادة المحاولة',
    super.code,
    super.details,
  });
}

class AudioPlayerException extends AppException {
  const AudioPlayerException({
    super.message = 'حدث خطأ أثناء تشغيل الملف الصوتي، يرجى المحاولة لاحقاً',
    super.code,
    super.details,
  });
}

class DownloadException extends AppException {
  const DownloadException({
    super.message = 'فشل تنزيل الأغنية، يرجى التحقق من الاتصال والمساحة المتوفرة',
    super.code,
    super.details,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'المحتوى المطلوب غير متوفر حالياً',
    super.code,
    super.details,
  });
}
