import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context

    @State private var exportURL: BackupFile? = nil
    @State private var showImporter = false
    @State private var importMode: ImportMode = .merge
    @State private var pendingImport: Data? = nil
    @State private var showImportDialog = false
    @State private var message: String? = nil
    @State private var showResetDefaultsConfirm = false

    enum ImportMode { case merge, replace }

    var body: some View {
        Form {
            Section("Backup & Restore") {
                Text("Export your inventory + custom database edits to a JSON file. " +
                     "The iOS share sheet lets you save to iCloud Drive, Google Drive, " +
                     "OneDrive, Dropbox, Files, or any installed provider.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    exportBackup()
                } label: {
                    Label("Export backup", systemImage: "square.and.arrow.up")
                }

                Button {
                    showImporter = true
                } label: {
                    Label("Import backup", systemImage: "square.and.arrow.down")
                }
            }

            Section("Database") {
                Text("Reset every edit to built-in defaults. Your inventory is not affected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Reset all default edits", role: .destructive) {
                    showResetDefaultsConfirm = true
                }
            }

            Section("About") {
                Text("FilamentVault v2.1.1 (iOS)")
                    .foregroundStyle(.primary)
                Text("3D printing filament inventory manager")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .fileExporter(
            item: exportURL,
            contentTypes: [.json],
            defaultFilename: defaultFilename()
        ) { result in
            switch result {
            case .success: message = "Backup saved"
            case .failure(let e): message = "Export failed: \(e.localizedDescription)"
            }
            exportURL = nil
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                handleImportURL(url)
            case .failure(let e):
                message = "Import cancelled: \(e.localizedDescription)"
            }
        }
        .confirmationDialog(
            "Restore from backup?",
            isPresented: $showImportDialog,
            titleVisibility: .visible
        ) {
            Button("Merge with current data") {
                performImport(replace: false)
            }
            Button("Replace everything", role: .destructive) {
                performImport(replace: true)
            }
            Button("Cancel", role: .cancel) { pendingImport = nil }
        } message: {
            Text("Merge adds to your existing inventory. Replace deletes everything first.")
        }
        .alert("Reset all default edits?", isPresented: $showResetDefaultsConfirm) {
            Button("Reset all", role: .destructive) {
                if let overrides = try? context.fetch(FetchDescriptor<DefaultOverride>()) {
                    for o in overrides { context.delete(o) }
                    try? context.save()
                    message = "All custom defaults cleared"
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Removes every custom default and restores built-in values. Inventory is not affected.")
        }
        .alert("Info", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK") { message = nil }
        } message: {
            Text(message ?? "")
        }
    }

    private func defaultFilename() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmmss"
        return "filamentvault_backup_\(df.string(from: Date()))"
    }

    private func exportBackup() {
        do {
            let data = try BackupService.export(context: context)
            exportURL = BackupFile(data: data)
        } catch {
            message = "Export failed: \(error.localizedDescription)"
        }
    }

    private func handleImportURL(_ url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            pendingImport = data
            showImportDialog = true
        } catch {
            message = "Could not read file: \(error.localizedDescription)"
        }
    }

    private func performImport(replace: Bool) {
        guard let data = pendingImport else { return }
        do {
            let (f, o) = try BackupService.importBundle(
                data: data,
                context: context,
                replaceExisting: replace
            )
            message = "Restored \(f) filaments, \(o) custom defaults"
        } catch {
            message = "Import failed: \(error.localizedDescription)"
        }
        pendingImport = nil
    }
}

// Wraps Data so SwiftUI's .fileExporter accepts it
struct BackupFile: FileDocument, Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { file in file.data }
    }
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
