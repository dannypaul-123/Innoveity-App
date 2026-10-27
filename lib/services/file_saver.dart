import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart' as impl;

Future<String?> saveAndDownloadFile(List<int> bytes, String fileName) =>
    impl.saveAndDownloadFile(bytes, fileName);
