// Jednoduché úložiště textových souborů podle jména.
// Mobil a desktop: soubory v dokumentech aplikace (stejně jako dřív).
// Web: localStorage prohlížeče (přes shared_preferences).
export 'storage_io.dart' if (dart.library.js_interop) 'storage_web.dart';
