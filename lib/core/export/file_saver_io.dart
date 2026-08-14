import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile/desktop: write the export to a temp file and hand it to the OS share
/// sheet so the user can save it or send it on.
Future<void> saveBytes(Uint8List bytes, String filename, String mime) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: mime)]),
  );
}
