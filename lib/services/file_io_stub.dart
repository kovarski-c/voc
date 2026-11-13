/// Mimo web (mobil, desktop) nejsou tyto funkce k dispozici.
bool get fileIoSupported => false;

Future<void> saveTextFile(String filename, String text) async =>
    throw UnsupportedError('Ukládání souboru je jen na webu.');

Future<String?> pickTextFile() async => null;

void reloadPage() {}
