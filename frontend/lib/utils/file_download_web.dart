import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<void> triggerFileDownload(String filename, List<int> bytes) async {
  final uint8 = Uint8List.fromList(bytes);

  final jsUint8 = uint8.toJS;

  final blobParts = <JSAny>[jsUint8].toJS;

  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: "text/csv"));

  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;

  web.document.body!.appendChild(anchor);
  anchor.click();

  anchor.remove();
  web.URL.revokeObjectURL(url);
}
