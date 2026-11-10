/// Final builds never construct Storage. Demonstrations require an explicit
/// mode and a known loopback/emulator host; invalid input fails closed.
enum PdfExportMode { finalLocal, storageEmulatorDemo }

const pdfExportModeName = String.fromEnvironment('PDF_EXPORT_MODE');
const storageEmulatorHost = String.fromEnvironment('STORAGE_EMULATOR_HOST');
const reportMetadataPendingAfter = Duration(seconds: 15);

bool isLocalStorageHost(String host) =>
    const {'10.0.2.2', '127.0.0.1', 'localhost'}.contains(host);

PdfExportMode resolvePdfExportMode({
  String mode = pdfExportModeName,
  String emulatorHost = storageEmulatorHost,
}) => mode == 'storage_emulator_demo' && isLocalStorageHost(emulatorHost)
    ? PdfExportMode.storageEmulatorDemo
    : PdfExportMode.finalLocal;
