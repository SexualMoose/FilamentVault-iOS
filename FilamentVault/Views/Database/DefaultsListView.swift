import SwiftUI
import SwiftData

struct DefaultsListView: View {
    @Environment(\.modelContext) private var context
    @Query private var defaults: [DefaultSetting]
    @Query private var overrides: [DefaultOverride]

    @State private var search: String = ""
    @State private var showingNewSheet = false

    struct Row: Identifiable {
        let id: String
        let materialType: String
        let brand: String?
        let fillType: String?
        let nozzleTempMin: Int?
        let nozzleTempMax: Int?
        let bedTempMin: Int?
        let bedTempMax: Int?
        let isModified: Bool
        let isCustom: Bool
        let baseDefault: DefaultSetting?
        let override: DefaultOverride?
    }

    var rows: [Row] {
        // Build merged view: each DefaultSetting either appears pristine OR with override values
        let overrideMap = Dictionary(
            uniqueKeysWithValues: overrides
                .compactMap { ovr -> (String, DefaultOverride)? in
                    guard let mat = ovr.baseMaterial else { return nil }
                    let key = "\(mat)||\(ovr.baseBrand ?? "")||\(ovr.baseFillType ?? "")"
                    return (key, ovr)
                }
        )

        var result: [Row] = []

        // Customs first (baseMaterial == nil means user-created)
        for ovr in overrides where ovr.baseMaterial == nil {
            result.append(Row(
                id: "custom-\(ovr.persistentModelID.hashValue)",
                materialType: ovr.materialType,
                brand: ovr.brand,
                fillType: ovr.fillType,
                nozzleTempMin: ovr.nozzleTempMin,
                nozzleTempMax: ovr.nozzleTempMax,
                bedTempMin: ovr.bedTempMin,
                bedTempMax: ovr.bedTempMax,
                isModified: false,
                isCustom: true,
                baseDefault: nil,
                override: ovr
            ))
        }

        // Built-ins (with override values applied where present)
        for d in defaults {
            let key = "\(d.materialType)||\(d.brand ?? "")||\(d.fillType ?? "")"
            let ovr = overrideMap[key]
            let effective = ovr?.toDefaultSetting() ?? d
            result.append(Row(
                id: "base-\(d.persistentModelID.hashValue)",
                materialType: effective.materialType,
                brand: effective.brand,
                fillType: effective.fillType,
                nozzleTempMin: effective.nozzleTempMin,
                nozzleTempMax: effective.nozzleTempMax,
                bedTempMin: effective.bedTempMin,
                bedTempMax: effective.bedTempMax,
                isModified: ovr != nil,
                isCustom: false,
                baseDefault: d,
                override: ovr
            ))
        }

        // Filter by search
        let filtered: [Row]
        if search.isEmpty {
            filtered = result
        } else {
            let q = search.lowercased()
            filtered = result.filter {
                $0.materialType.lowercased().contains(q) ||
                ($0.brand?.lowercased().contains(q) ?? false) ||
                ($0.fillType?.lowercased().contains(q) ?? false)
            }
        }

        // Sort: customs first, then material, brand, fillType
        return filtered.sorted { a, b in
            if a.isCustom != b.isCustom { return a.isCustom && !b.isCustom }
            if a.materialType != b.materialType { return a.materialType < b.materialType }
            if (a.brand ?? "") != (b.brand ?? "") { return (a.brand ?? "") < (b.brand ?? "") }
            return (a.fillType ?? "") < (b.fillType ?? "")
        }
    }

    var body: some View {
        List {
            Section {
                Text("\(rows.count) entries · \(rows.filter(\.isModified).count) modified · \(rows.filter(\.isCustom).count) custom")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(rows) { row in
                NavigationLink {
                    DefaultsEditorView(
                        baseDefault: row.baseDefault,
                        existingOverride: row.override
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(row.materialType).font(.headline)
                            if row.isCustom {
                                badge("Custom", color: .purple)
                            } else if row.isModified {
                                badge("Modified", color: .blue)
                            }
                        }
                        let subtitle = [row.brand, row.fillType]
                            .compactMap { $0 }
                            .joined(separator: " · ")
                        if !subtitle.isEmpty {
                            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                        } else {
                            Text("Generic fallback").font(.subheadline).foregroundStyle(.tertiary)
                        }
                        if row.nozzleTempMin != nil || row.bedTempMin != nil {
                            Text(tempSummary(row)).font(.caption).foregroundStyle(.blue.opacity(0.85))
                        }
                    }
                }
            }
        }
        .navigationTitle("Filament Database")
        .searchable(text: $search, prompt: "Search material, brand, modifier")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingNewSheet) {
            NavigationStack {
                DefaultsEditorView(baseDefault: nil, existingOverride: nil)
            }
        }
    }

    private func tempSummary(_ row: Row) -> String {
        var parts: [String] = []
        if let minN = row.nozzleTempMin, let maxN = row.nozzleTempMax {
            parts.append("Nozzle \(minN)-\(maxN)°C")
        } else if let minN = row.nozzleTempMin {
            parts.append("Nozzle \(minN)°C")
        }
        if let minB = row.bedTempMin, let maxB = row.bedTempMax {
            parts.append("Bed \(minB)-\(maxB)°C")
        }
        return parts.joined(separator: "  ·  ")
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2).bold()
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}
