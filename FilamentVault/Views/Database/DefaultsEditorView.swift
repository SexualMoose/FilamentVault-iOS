import SwiftUI
import SwiftData

struct DefaultsEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// The built-in entry this row represents (nil when editing a custom).
    let baseDefault: DefaultSetting?
    /// Saved override for this row (nil when built-in has no override yet).
    @State var existingOverride: DefaultOverride?

    @State private var materialType: String = "PLA"
    @State private var brand: String = ""
    @State private var fillType: String = "Standard"
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
    @State private var filamentDiameter: Double = 1.75
    @State private var dryingTemp: String = ""
    @State private var dryingTime: String = ""
    @State private var moistureSensitivity: String = ""

    @State private var showResetConfirm = false
    @State private var showDeleteConfirm = false

    private var isBuiltIn: Bool { baseDefault != nil && existingOverride == nil }
    private var isModified: Bool { baseDefault != nil && existingOverride != nil }
    private var isCustom: Bool { baseDefault == nil && existingOverride != nil }
    private var canSave: Bool { !materialType.isEmpty }

    var body: some View {
        Form {
            Section("Identity") {
                Picker("Material", selection: $materialType) {
                    ForEach(MaterialType.allCases) { m in Text(m.displayName).tag(m.rawValue) }
                }
                Picker("Modifier", selection: $fillType) {
                    ForEach(FillType.allCases) { f in Text(f.displayName).tag(f.rawValue) }
                }
                TextField("Brand", text: $brand)
                Picker("Diameter", selection: $filamentDiameter) {
                    Text("1.75 mm").tag(1.75)
                    Text("2.85 mm").tag(2.85)
                }
                .pickerStyle(.segmented)
            }

            Section("Temperatures") {
                num("Nozzle Min (°C)", $nozzleTempMin)
                num("Nozzle Max (°C)", $nozzleTempMax)
                num("Bed Min (°C)", $bedTempMin)
                num("Bed Max (°C)", $bedTempMax)
                num("Chamber (°C)", $chamberTemp)
            }

            Section("Speeds & Cooling") {
                num("Print Speed Min (mm/s)", $printSpeedMin)
                num("Print Speed Max (mm/s)", $printSpeedMax)
                dec("Max Volumetric (mm³/s)", $maxVolumetricSpeed)
                num("Fan Min (%)", $fanSpeedMin)
                num("Fan Max (%)", $fanSpeedMax)
                TextField("Fan Notes", text: $fanSpeedNotes)
            }

            Section("Retraction / Flow / Layer") {
                dec("Retraction Distance (mm)", $retractionDistance)
                dec("Retraction Speed (mm/s)", $retractionSpeed)
                dec("Flow Rate (%)", $flowRate)
                dec("Layer Min (mm)", $layerHeightMin)
                dec("Layer Max (mm)", $layerHeightMax)
            }

            Section("Physical & Drying") {
                dec("Density (g/cm³)", $density)
                num("Drying Temp (°C)", $dryingTemp)
                num("Drying Time (hrs)", $dryingTime)
                TextField("Moisture Sensitivity", text: $moistureSensitivity)
            }

            Section {
                if isBuiltIn || isModified {
                    Button("Save (overrides built-in — original preserved)") { saveOverride() }
                        .disabled(!canSave)
                    Button("Save as new entry") { saveAsNew() }
                        .disabled(!canSave)
                    Button(isModified ? "Reset to original" : "Reset fields to built-in") {
                        showResetConfirm = true
                    }
                    .foregroundStyle(.orange)
                } else if isCustom {
                    Button("Save changes") { saveCustom() }
                        .disabled(!canSave)
                    Button("Duplicate as new entry") { saveAsNew() }
                        .disabled(!canSave)
                    Button("Delete", role: .destructive) { showDeleteConfirm = true }
                } else {
                    Button("Save new default") { saveAsNew() }
                        .disabled(!canSave)
                }
            }
        }
        .navigationTitle(
            isCustom ? "Edit Custom" :
            isModified ? "Edit Default (modified)" :
            isBuiltIn ? "Edit Default" : "New Default"
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
        .alert("Reset to original?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { resetToBuiltIn() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(isModified
                 ? "Removes your saved edits and restores the built-in values."
                 : "Discards unsaved changes and reloads the built-in values.")
        }
        .alert("Delete custom default?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteCustom() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes this user-created default.")
        }
    }

    private func num(_ label: String, _ value: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
        }
    }

    private func dec(_ label: String, _ value: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
        }
    }

    private func load() {
        let source: DefaultSetting? = existingOverride?.toDefaultSetting() ?? baseDefault
        guard let s = source else { return }
        materialType = s.materialType
        brand = s.brand ?? ""
        fillType = s.fillType ?? "Standard"
        nozzleTempMin = s.nozzleTempMin.map(String.init) ?? ""
        nozzleTempMax = s.nozzleTempMax.map(String.init) ?? ""
        bedTempMin = s.bedTempMin.map(String.init) ?? ""
        bedTempMax = s.bedTempMax.map(String.init) ?? ""
        chamberTemp = s.chamberTemp.map(String.init) ?? ""
        printSpeedMin = s.printSpeedMin.map(String.init) ?? ""
        printSpeedMax = s.printSpeedMax.map(String.init) ?? ""
        maxVolumetricSpeed = s.maxVolumetricSpeed.map { "\($0)" } ?? ""
        fanSpeedMin = s.fanSpeedMin.map(String.init) ?? ""
        fanSpeedMax = s.fanSpeedMax.map(String.init) ?? ""
        fanSpeedNotes = s.fanSpeedNotes ?? ""
        retractionDistance = s.retractionDistance.map { "\($0)" } ?? ""
        retractionSpeed = s.retractionSpeed.map { "\($0)" } ?? ""
        flowRate = s.flowRate.map { "\($0)" } ?? ""
        layerHeightMin = s.layerHeightMin.map { "\($0)" } ?? ""
        layerHeightMax = s.layerHeightMax.map { "\($0)" } ?? ""
        density = s.density.map { "\($0)" } ?? ""
        filamentDiameter = s.filamentDiameter
        dryingTemp = s.dryingTemp.map(String.init) ?? ""
        dryingTime = s.dryingTime.map(String.init) ?? ""
        moistureSensitivity = s.moistureSensitivity ?? ""
    }

    private func buildOverride(baseOn base: DefaultSetting?) -> DefaultOverride {
        DefaultOverride(
            baseMaterial: base?.materialType,
            baseBrand: base?.brand,
            baseFillType: base?.fillType,
            materialType: materialType,
            brand: brand.isEmpty ? nil : brand,
            fillType: fillType.isEmpty ? "Standard" : fillType,
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
            filamentDiameter: filamentDiameter,
            dryingTemp: Int(dryingTemp),
            dryingTime: Int(dryingTime),
            moistureSensitivity: moistureSensitivity.isEmpty ? nil : moistureSensitivity
        )
    }

    private func copyFields(into o: DefaultOverride) {
        o.materialType = materialType
        o.brand = brand.isEmpty ? nil : brand
        o.fillType = fillType.isEmpty ? "Standard" : fillType
        o.nozzleTempMin = Int(nozzleTempMin)
        o.nozzleTempMax = Int(nozzleTempMax)
        o.bedTempMin = Int(bedTempMin)
        o.bedTempMax = Int(bedTempMax)
        o.chamberTemp = Int(chamberTemp)
        o.printSpeedMin = Int(printSpeedMin)
        o.printSpeedMax = Int(printSpeedMax)
        o.maxVolumetricSpeed = Double(maxVolumetricSpeed)
        o.fanSpeedMin = Int(fanSpeedMin)
        o.fanSpeedMax = Int(fanSpeedMax)
        o.fanSpeedNotes = fanSpeedNotes.isEmpty ? nil : fanSpeedNotes
        o.retractionDistance = Double(retractionDistance)
        o.retractionSpeed = Double(retractionSpeed)
        o.flowRate = Double(flowRate)
        o.layerHeightMin = Double(layerHeightMin)
        o.layerHeightMax = Double(layerHeightMax)
        o.density = Double(density)
        o.filamentDiameter = filamentDiameter
        o.dryingTemp = Int(dryingTemp)
        o.dryingTime = Int(dryingTime)
        o.moistureSensitivity = moistureSensitivity.isEmpty ? nil : moistureSensitivity
        o.updatedAt = .now
    }

    private func saveOverride() {
        if let existing = existingOverride {
            copyFields(into: existing)
        } else {
            let new = buildOverride(baseOn: baseDefault)
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }

    private func saveAsNew() {
        let new = buildOverride(baseOn: nil)  // nil baseMaterial = user-created
        new.baseMaterial = nil
        new.baseBrand = nil
        new.baseFillType = nil
        context.insert(new)
        try? context.save()
        dismiss()
    }

    private func saveCustom() {
        if let existing = existingOverride {
            copyFields(into: existing)
            try? context.save()
        }
        dismiss()
    }

    private func resetToBuiltIn() {
        if let existing = existingOverride {
            context.delete(existing)
            existingOverride = nil
            try? context.save()
        }
        load()
    }

    private func deleteCustom() {
        if let existing = existingOverride {
            context.delete(existing)
            try? context.save()
        }
        dismiss()
    }
}
