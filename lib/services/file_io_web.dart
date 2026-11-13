import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool get fileIoSupported => true;

bool get _isIos {
  final nav = web.window.navigator;
  final ua = nav.userAgent;
  return ua.contains('iPhone') ||
      ua.contains('iPad') ||
      (ua.contains('Macintosh') && nav.maxTouchPoints > 1);
}

/// Uloží text jako soubor. Na iOS se otevře nabídka Sdílet (Uložit do Souborů),
/// jinde se soubor stáhne. Klasické stažení v aplikaci přidané na plochu iOS
/// často nefunguje, proto ta nabídka.
Future<void> saveTextFile(String filename, String text) async {
  if (_isIos) {
    try {
      final file = web.File(
        [text.toJS].toJS,
        filename,
        web.FilePropertyBag(type: 'application/json'),
      );
      final data = web.ShareData(files: [file].toJS);
      if (web.window.navigator.canShare(data)) {
        await web.window.navigator.share(data).toDart;
        return;
      }
    } catch (e) {
      // Zavření nabídky uživatelem není chyba.
      if ('$e'.contains('Abort')) return;
    }
  }
  final blob = web.Blob(
    [text.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement;
  a.href = url;
  a.download = filename;
  a.style.display = 'none';
  web.document.body!.append(a);
  a.click();
  a.remove();
  Timer(const Duration(seconds: 10), () => web.URL.revokeObjectURL(url));
}

/// Nechá uživatele vybrat soubor a vrátí jeho text (null = nic nevybral).
/// Musí se volat přímo z klepnutí na tlačítko.
Future<String?> pickTextFile() {
  final done = Completer<String?>();
  void finish(String? v) {
    if (!done.isCompleted) done.complete(v);
  }

  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept = '.json,application/json';
  input.style.display = 'none';
  input.onchange = ((web.Event _) {
    final f = input.files?.item(0);
    if (f == null) {
      finish(null);
    } else {
      f.text().toDart.then((s) => finish(s.toDart), onError: (_) => finish(null));
    }
    input.remove();
  }).toJS;
  input.addEventListener(
    'cancel',
    ((web.Event _) {
      finish(null);
      input.remove();
    }).toJS,
  );
  web.document.body!.append(input);
  input.click();
  return done.future;
}

void reloadPage() => web.window.location.reload();
