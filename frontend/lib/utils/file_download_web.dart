import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> triggerFileDownload(String filename, List<int> bytes) async {
  final jsBytes = bytes.map((b) => b.toJS).toList().toJS;
  final blob = web.Blob(jsBytes, web.BlobPropertyBag(type: 'application/octet-stream'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  web.document.body!.appendChild(anchor);
  anchor.click();
  web.document.body!.removeChild(anchor);
  web.URL.revokeObjectURL(url);
}
