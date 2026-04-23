import SwiftUI
import SwiftData
import PhotosUI

struct FilamentDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allFilaments: [Filament]
    @Query private var allDefaults: [DefaultSetting]
    @Query private var allOverrides: [DefaultOverride]

    /// nil = adding new; non-nil = editing existing
    let filament: Filament?

    // ── Form state ──
    @State private var materialType: String = "PLA"
    @State private var colorHex: String = "#FF5733"
    @State private var fillType: String = "Standard"
    @State private var colorName: String = ""
    @State private var brand: String = ""
    @State private var filamentDiameter: Double = 1.75
    @State private var nozzleTempMin: String = ""
    @State private var nozzleTempMax: String = ""
    @State private var bedTempMin: String = ""
    @State private var bedTempMax: String = ""
    @State private var chamberTemp: String = ""
    @State private var printSpeedMin: String = ""
    @State private var printSpeedMax: String = ""
    @State private var maxVolumetricSpeed: String = ""
    @State private var fanSpeedMin: String = ""
    @State private var fanSpeedMax: String = ""
    @State private var fanSpeedNotes: String = ""
    @State private var retractionDistance: String = ""
    @State private var retractionSpeed: String = ""
    @State private var flowRate: String = ""
    @State private var layerHeightMin: String = ""
    @State private var layerHeightMax: String = ""
    @State private var density: String = ""
    @State private var dryingTemp: String = ""
    @State private var dryingTime: String = ""
    @State private var moistureSensitivity: String = ""
    @State private var quantity: Int = 1
    @State private var notes: String = ""
    @State private var imageFilename: String?
    @State private var originalImageFilename: String?

    // UI state
    @State private var touched = Set<String>()
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showCropper = false
    @State private var cropSourceFilename: String?
    @State private var duplicateMatch: Filament?
    @State private var showDuplicateSheet = false

    private var isEditing: Bool { filament != nil }
    private var canSave: Bool { !materialType.isEmpty && !colorHex.isEmpty }

    var body: some View {
        Form {
            identitySection
            quantitySection
            temperatureSection
            speedsSection
            retractionSection
            physicalSection
            notesSection
            photoSection
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(isEditing ? "Edit Filament" : "Add Filament")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { attemptSave() }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
            }
        }
        .onAppear { loadForm() }
        .onChange(of: materialType) { _, _ in applyDefaultsIfFresh() }
        .onChange(of: fillType)    { _, _ in applyDefaultsIfFresh() }
        .onChange(of: brand)       { _, _ in applyDefaultsIfFresh(debounce: true) }
        .photosPicker(
            isPresented: Binding(
                get: { photoPickerItem != nil && false },  // never shows; we use PhotosPicker below
                set: { _ in }
            ),
            selection: $photoPickerItem
        )
        .sheet(isPresented: $showCropper) {
            if let src = cropSourceFilename {
                SpoolCropperView(sourceFilename: src) { croppedFilename in
                    imageFilename = croppedFilename
                    showCropper = false
                }
            }
        }
        .sheet(isPresented: $showDuplicateSheet) {
            duplicateSheet
        }
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            Task { await handlePhotoPick(item) }
        }
    }

    // MARK: - Sections

    private var identitySection: some View {
        Section("Identity") {
            Picker("Material", selection: $materialType) {
                ForEach(MaterialType.allCases) { mat in
                    Text(mat.displayName).tag(mat.rawValue)
                }
            }

            Picker("Modifier", selection: $fillType) {
                ForEach(FillType.allCases) { f in
                    Text(f.displayName).tag(f.rawValue)
                }
            }

            BrandAutocomplete(value: $brand, availableBrands: availableBrands)

            HStack {
                ColorSwatchSpool(colorHex: colorHex, size: 40)
                TextField("Color Hex *", text: $colorHex)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
            }

            TextField("Color Name", text: $colorName)

            Picker("Diameter", selection: $filamentDiameter) {
                Text("1.75 mm").tag(1.75)
                Text("2.85 mm").tag(2.85)
            }
            .pickerStyle(.segmented)
        }
    }

    private var quantitySection: some View {
        Section {
            HStack {
                Text("Quantity")
                Spacer()
                Button {
                    if quantity > 1 { quantity -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(quantity <= 1)

                Text("\(quantity)")
                    .font(.title3).bold()
                    .frame(minWidth: 40)
                    .multilineTextAlignment(.center)

                Button {
                    quantity += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var temperatureSection: some View {
        Section("Temperatures") {
            numField("Nozzle Min (°C)", $nozzleTempMin, "nozzleTempMin")
            numField("Nozzle Max (°C)", $nozzleTempMax, "nozzleTempMax")
            numField("Bed Min (°C)",    $bedTempMin,    "bedTempMin")
            numField("Bed Max (°C)",    $bedTempMax,    "bedTempMax")
            numField("Chamber (°C)",    $chamberTemp,   "chamberTemp")
        }
    }

    private var speedsSection: some View {
        Section("Speeds & Cooling") {
            numField("Print Speed Min (mm/s)", $printSpeedMin, "printSpeedMin")
            numField("Print Speed Max (mm/s)", $printSpeedMax, "printSpeedMax")
            decField("Max Volumetric (mm³/s)", $maxVolumetricSpeed, "maxVolumetricSpeed")
            numField("Fan Min (%)", $fanSpeedMin, "fanSpeedMin")
            numField("Fan Max (%)", $fanSpeedMax, "fanSpeedMax")
            TextField("Fan Notes", text: $fanSpeedNotes)
                .onChange(of: fanSpeedNotes) { _, _ in touched.insert("fanSpeedNotes") }
        }
    }

    private var retractionSection: some View {
        Section("Retraction / Flow / Layer") {
            decField("Retraction Distance (mm)", $retractionDistance, "retractionDistance")
            decField("Retraction Speed (mm/s)",  $retractionSpeed,    "retractionSpeed")
            decField("Flow Rate (%)",            $flowRate,           "flowRate")
            decField("Layer Min (mm)",           $layerHeightMin,     "layerHeightMin")
            decField("Layer Max (mm)",           $layerHeightMax,     "layerHeightMax")
        }
    }

    private var physicalSection: some View {
        Section("Physical & Drying") {
            decField("Density (g/cm³)", $density, "density")
            numField("Drying Temp (°C)", $dryingTemp, "dryingTemp")
            numField("Drying Time (hrs)", $dryingTime, "dryingTime")
            TextField("Moisture Sensitivity", text: $moistureSensitivity)
                .onChange(of: moistureSensitivity) { _, _ in touched.insert("moistureSensitivity") }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var photoSection: some View {
        Section("Photo") {
            if let filename = imageFilename,
               let img = ImageStorage.load(filename) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                HStack {
                    if let original = originalImageFilename {
                        Button {
                            cropSourceFilename = original
                            showCropper = true
                        } label: {
                            Label("Recrop", systemImage: "crop")
                        }
                    }
                    Spacer()
                    Button(role: .destructive) {
                        ImageStorage.delete(imageFilename)
                        if let orig = originalImageFilename, orig != imageFilename {
                            ImageStorage.delete(orig)
                        }
                        imageFilename = nil
                        originalImageFilename = nil
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
            PhotosPicker(
                selection: $photoPickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(imageFilename == nil ? "Add Photo" : "Change Photo",
                      systemImage: "photo.on.rectangle.angled")
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func numField(_ label: String, _ value: Binding<String>, _ key: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .onChange(of: value.wrappedValue) { _, _ in touched.insert(key) }
        }
    }

    @ViewBuilder
    private func decField(_ label: String, _ value: Binding<String>, _ key: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .onChange(of: value.wrappedValue) { _, _ in touched.insert(key) }
        }
    }

    private var availableBrands: [String] {
        var s = Set<String>()
        for f in allFilaments { if let b = f.brand { s.insert(b) } }
        for d in allDefaults  { if let b = d.brand { s.insert(b) } }
        for o in allOverrides { if let b = o.brand { s.insert(b) } }
        return s.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // MARK: - Load + auto-populate

    private func loadForm() {
        guard let f = filament else { return }
        materialType = f.materialType
        colorHex = f.colorHex
        fillType = f.fillType ?? "Standard"
        colorName = f.colorName ?? ""
        brand = f.brand ?? ""
        filamentDiameter = f.filamentDiameter
        nozzleTempMin = f.nozzleTempMin.map(String.init) ?? ""
        nozzleTempMax = f.nozzleTempMax.map(String.init) ?? ""
        bedTempMin = f.bedTempMin.map(String.init) ?? ""
        bedTempMax = f.bedTempMax.map(String.init) ?? ""
        chamberTemp = f.chamberTemp.map(String.init) ?? ""
        printSpeedMin = f.printSpeedMin.map(String.init) ?? ""
        printSpeedMax = f.printSpeedMax.map(String.init) ?? ""
        maxVolumetricSpeed = f.maxVolumetricSpeed.map { "\($0)" } ?? ""
        fanSpeedMin = f.fanSpeedMin.map(String.init) ?? ""
        fanSpeedMax = f.fanSpeedMax.map(String.init) ?? ""
        fanSpeedNotes = f.fanSpeedNotes ?? ""
        retractionDistance = f.retractionDistance.map { "\($0)" } ?? ""
        retractionSpeed = f.retractionSpeed.map { "\($0)" } ?? ""
        flowRate = f.flowRate.map { "\($0)" } ?? ""
        layerHeightMin = f.layerHeightMin.map { "\($0)" } ?? ""
        layerHeightMax = f.layerHeightMax.map { "\($0)" } ?? ""
        density = f.density.map { "\($0)" } ?? ""
        dryingTemp = f.dryingTemp.map(String.init) ?? ""
        dryingTime = f.dryingTime.map(String.init) ?? ""
        moistureSensitivity = f.moistureSensitivity ?? ""
        quantity = f.quantity
        notes = f.notes ?? ""
        imageFilename = f.imageFilename
        originalImageFilename = f.originalImageFilename
    }

    @State private var debounceTask: Task<Void, Never>?

    private func applyDefaultsIfFresh(debounce: Bool = false) {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            if debounce { try? await Task.sleep(nanoseconds: 500_000_000) }
            if Task.isCancelled { return }
            guard let defaults = DefaultsPopulator.lookupDefaults(
                context: context,
                materialType: materialType,
                brand: brand.isEmpty ? nil : brand,
                fillType: fillType.isEmpty ? nil : fillType
            ) else { return }

            if !touched.contains("nozzleTempMin"), let v = defaults.nozzleTempMin { nozzleTempMin = "\(v)" }
            if !touched.contains("nozzleTempMax"), let v = defaults.nozzleTempMax { nozzleTempMax = "\(v)" }
            if !touched.contains("bedTempMin"), let v = defaults.bedTempMin { bedTempMin = "\(v)" }
            if !touched.contains("bedTempMax"), let v = defaults.bedTempMax { bedTempMax = "\(v)" }
            if !touched.contains("chamberTemp"), let v = defaults.chamberTemp { chamberTemp = "\(v)" }
            if !touched.contains("printSpeedMin"), let v = defaults.printSpeedMin { printSpeedMin = "\(v)" }
            if !touched.contains("printSpeedMax"), let v = defaults.printSpeedMax { printSpeedMax = "\(v)" }
            if !touched.contains("maxVolumetricSpeed"), let v = defaults.maxVolumetricSpeed { maxVolumetricSpeed = "\(v)" }
            if !touched.contains("fanSpeedMin"), let v = defaults.fanSpeedMin { fanSpeedMin = "\(v)" }
            if !touched.contains("fanSpeedMax"), let v = defaults.fanSpeedMax { fanSpeedMax = "\(v)" }
            if !touched.contains("fanSpeedNotes"), let v = defaults.fanSpeedNotes { fanSpeedNotes = v }
            if !touched.contains("retractionDistance"), let v = defaults.retractionDistance { retractionDistance = "\(v)" }
            if !touched.contains("retractionSpeed"), let v = defaults.retractionSpeed { retractionSpeed = "\(v)" }
            if !touched.contains("flowRate"), let v = defaults.flowRate { flowRate = "\(v)" }
            if !touched.contains("layerHeightMin"), let v = defaults.layerHeightMin { layerHeightMin = "\(v)" }
            if !touched.contains("layerHeightMax"), let v = defaults.layerHeightMax { layerHeightMax = "\(v)" }
            if !touched.contains("density"), let v = defaults.density { density = "\(v)" }
            if !touched.contains("dryingTemp"), let v = defaults.dryingTemp { dryingTemp = "\(v)" }
            if !touched.contains("dryingTime"), let v = defaults.dryingTime { dryingTime = "\(v)" }
            if !touched.contains("moistureSensitivity"), let v = defaults.moistureSensitivity { moistureSensitivity = v }
        }
    }

    // MARK: - Save + duplicate detection

    private func attemptSave() {
        if filament == nil {
            // Duplicate check on new entries
            let match = allFilaments.first {
                $0.materialType == materialType &&
                $0.colorHex == colorHex &&
                abs($0.filamentDiameter - filamentDiameter) < 0.001 &&
                ($0.brand ?? "") == brand &&
                ($0.fillType ?? "Standard") == fillType
            }
            if let match {
                duplicateMatch = match
                showDuplicateSheet = true
                return
            }
        }
        performSave()
    }

    private func performSave() {
        let now = Date.now
        if let existing = filament {
            existing.materialType = materialType
            existing.colorHex = colorHex
            existing.fillType = fillType.isEmpty ? "Standard" : fillType
            existing.colorName = colorName.isEmpty ? nil : colorName
            existing.brand = brand.isEmpty ? nil : brand
            existing.filamentDiameter = filamentDiameter
            existing.nozzleTempMin = Int(nozzleTempMin)
            existing.nozzleTempMax = Int(nozzleTempMax)
            existing.bedTempMin = Int(bedTempMin)
            existing.bedTempMax = Int(bedTempMax)
            existing.chamberTemp = Int(chamberTemp)
            existing.printSpeedMin = Int(printSpeedMin)
            existing.printSpeedMax = Int(printSpeedMax)
            existing.maxVolumetricSpeed = Double(maxVolumetricSpeed)
            existing.fanSpeedMin = Int(fanSpeedMin)
            existing.fanSpeedMax = Int(fanSpeedMax)
            existing.fanSpeedNotes = fanSpeedNotes.isEmpty ? nil : fanSpeedNotes
            existing.retractionDistance = Double(retractionDistance)
            existing.retractionSpeed = Double(retractionSpeed)
            existing.flowRate = Double(flowRate)
            existing.layerHeightMin = Double(layerHeightMin)
            existing.layerHeightMax = Double(layerHeightMax)
            existing.density = Double(density)
            existing.dryingTemp = Int(dryingTemp)
            existing.dryingTime = Int(dryingTime)
            existing.moistureSensitivity = moistureSensitivity.isEmpty ? nil : moistureSensitivity
            existing.quantity = quantity
            existing.notes = notes.isEmpty ? nil : notes
            existing.imageFilename = imageFilename
            existing.originalImageFilename = originalImageFilename
            existing.updatedAt = now
        } else {
            let new = Filament(
                materialType: materialType,
                colorHex: colorHex,
                fillType: fillType.isEmpty ? "Standard" : fillType,
                colorName: colorName.isEmpty ? nil : colorName,
                brand: brand.isEmpty ? nil : brand,
                filamentDiameter: filamentDiameter,
                nozzleTempMin: Int(nozzleTempMin),
                nozzleTempMax: Int(nozzleTempMax),
                bedTempMin: Int(bedTempMin),
                bedTempMax: Int(bedTempMax),
                chamberTemp: Int(chamberTemp),
                printSpeedMin: Int(printSpeedMin),
                printSpeedMax: Int(printSpeedMax),
                maxVolumetricSpeed: Double(maxVolumetricSpeed),
                fanSpeedMin: Int(fanSpeedMin),
                fanSpeedMax: Int(fanSpeedMax),
                fanSpeedNotes: fanSpeedNotes.isEmpty ? nil : fanSpeedNotes,
                retractionDistance: Double(retractionDistance),
                retractionSpeed: Double(retractionSpeed),
                flowRate: Double(flowRate),
                layerHeightMin: Double(layerHeightMin),
                layerHeightMax: Double(layerHeightMax),
                density: Double(density),
                dryingTemp: Int(dryingTemp),
                dryingTime: Int(dryingTime),
                moistureSensitivity: moistureSensitivity.isEmpty ? nil : moistureSensitivity,
                quantity: quantity,
                notes: notes.isEmpty ? nil : notes,
                imageFilename: imageFilename,
                originalImageFilename: originalImageFilename
            )
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }

    private var duplicateSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                Text("Duplicate Filament")
                    .font(.title2).bold()
                if let m = duplicateMatch {
                    let desc = [m.materialType, m.brand, m.colorName]
                        .compactMap { $0 }.joined(separator: " · ")
                    Text("You already have \(m.quantity) spool(s) of \(desc).")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text("Add another spool to bring the count to \(m.quantity + 1), or cancel this entry.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
                VStack(spacing: 8) {
                    Button {
                        if let m = duplicateMatch {
                            m.quantity += 1
                            m.updatedAt = .now
                            try? context.save()
                        }
                        showDuplicateSheet = false
                        dismiss()
                    } label: {
                        Text("Add Spool (+1)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button("Cancel Entry") {
                        showDuplicateSheet = false
                    }
                    .padding(.vertical, 8)
                }
                .padding()
            }
            .padding(.top, 40)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Photo handling

    private func handlePhotoPick(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let img = UIImage(data: data) else { return }
        // Save original, trigger cropper
        if let filename = ImageStorage.save(img, prefix: "original") {
            await MainActor.run {
                // Clean previous
                ImageStorage.delete(imageFilename)
                if let oldOrig = originalImageFilename, oldOrig != imageFilename {
                    ImageStorage.delete(oldOrig)
                }
                imageFilename = filename
                originalImageFilename = filename
                cropSourceFilename = filename
                showCropper = true
                photoPickerItem = nil
            }
        }
    }
}
