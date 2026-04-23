import Foundation
import SwiftData

/// Reads defaults.json from the app bundle and seeds the DefaultSetting table.
/// Re-seeds whenever the bundled JSON has a different entry count than the DB
/// (lets us ship catalog updates without wiping user data).
enum DefaultsPopulator {

    struct JsonDefault: Codable {
        var materialType: String
        var brand: String?
        var fillType: String?
        var nozzleTempMin: Int?
        var nozzleTempMax: Int?
        var bedTempMin: Int?
        var bedTempMax: Int?
        var chamberTemp: Int?
        var printSpeedMin: Int?
        var printSpeedMax: Int?
        var maxVolumetricSpeed: Double?
        var fanSpeedMin: Int?
        var fanSpeedMax: Int?
        var fanSpeedNotes: String?
        var retractionDistance: Double?
        var retractionSpeed: Double?
        var flowRate: Double?
        var layerHeightMin: Double?
        var layerHeightMax: Double?
        var density: Double?
        var filamentDiameter: Double?
        var dryingTemp: Int?
        var dryingTime: Int?
        var moistureSensitivity: String?
    }

    struct Wrapper: Codable {
        var defaults: [JsonDefault]
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) async {
        do {
            let entries = try loadFromBundle()
            let existing = try context.fetch(FetchDescriptor<DefaultSetting>())
            if existing.count == entries.count { return }

            // Reseed: clear + reinsert. User filaments + overrides are untouched.
            for row in existing {
                context.delete(row)
            }
            for e in entries {
                context.insert(DefaultSetting(
                    materialType: e.materialType,
                    brand: e.brand,
                    fillType: e.fillType,
                    nozzleTempMin: e.nozzleTempMin,
                    nozzleTempMax: e.nozzleTempMax,
                    bedTempMin: e.bedTempMin,
                    bedTempMax: e.bedTempMax,
                    chamberTemp: e.chamberTemp,
                    printSpeedMin: e.printSpeedMin,
                    printSpeedMax: e.printSpeedMax,
                    maxVolumetricSpeed: e.maxVolumetricSpeed,
                    fanSpeedMin: e.fanSpeedMin,
                    fanSpeedMax: e.fanSpeedMax,
                    fanSpeedNotes: e.fanSpeedNotes,
                    retractionDistance: e.retractionDistance,
                    retractionSpeed: e.retractionSpeed,
                    flowRate: e.flowRate,
                    layerHeightMin: e.layerHeightMin,
                    layerHeightMax: e.layerHeightMax,
                    density: e.density,
                    filamentDiameter: e.filamentDiameter ?? 1.75,
                    dryingTemp: e.dryingTemp,
                    dryingTime: e.dryingTime,
                    moistureSensitivity: e.moistureSensitivity
                ))
            }
            try context.save()
        } catch {
            print("DefaultsPopulator failed: \(error)")
        }
    }

    private static func loadFromBundle() throws -> [JsonDefault] {
        guard let url = Bundle.main.url(forResource: "defaults", withExtension: "json") else {
            throw NSError(
                domain: "FilamentVault",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "defaults.json missing from app bundle"]
            )
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Wrapper.self, from: data).defaults
    }

    /// Cascading defaults lookup — override table wins over built-in catalog.
    /// Matches the 4-tier priority used on Android: exact → mat+brand → mat+fill → mat.
    @MainActor
    static func lookupDefaults(
        context: ModelContext,
        materialType: String,
        brand: String?,
        fillType: String?
    ) -> DefaultSetting? {
        // 1. Check overrides first
        let overrides = (try? context.fetch(FetchDescriptor<DefaultOverride>())) ?? []
        let orderedOverrides: [(String?, String?)] = [
            (brand, fillType), (brand, nil), (nil, fillType), (nil, nil)
        ]
        for (b, f) in orderedOverrides {
            if let match = overrides.first(where: {
                $0.materialType == materialType && $0.brand == b && $0.fillType == f
            }) {
                return match.toDefaultSetting()
            }
        }

        // 2. Fall back to built-in catalog
        let defaults = (try? context.fetch(FetchDescriptor<DefaultSetting>())) ?? []
        if let b = brand, let f = fillType,
           let exact = defaults.first(where: {
               $0.materialType == materialType && $0.brand == b && $0.fillType == f
           }) {
            return exact
        }
        if let b = brand,
           let hit = defaults.first(where: {
               $0.materialType == materialType && $0.brand == b && $0.fillType == nil
           }) {
            return hit
        }
        if let f = fillType,
           let hit = defaults.first(where: {
               $0.materialType == materialType && $0.brand == nil && $0.fillType == f
           }) {
            return hit
        }
        return defaults.first(where: {
            $0.materialType == materialType && $0.brand == nil && $0.fillType == nil
        })
    }
}

extension DefaultOverride {
    func toDefaultSetting() -> DefaultSetting {
        DefaultSetting(
            materialType: materialType,
            brand: brand,
            fillType: fillType,
            nozzleTempMin: nozzleTempMin,
            nozzleTempMax: nozzleTempMax,
            bedTempMin: bedTempMin,
            bedTempMax: bedTempMax,
            chamberTemp: chamberTemp,
            printSpeedMin: printSpeedMin,
            printSpeedMax: printSpeedMax,
            maxVolumetricSpeed: maxVolumetricSpeed,
            fanSpeedMin: fanSpeedMin,
            fanSpeedMax: fanSpeedMax,
            fanSpeedNotes: fanSpeedNotes,
            retractionDistance: retractionDistance,
            retractionSpeed: retractionSpeed,
            flowRate: flowRate,
            layerHeightMin: layerHeightMin,
            layerHeightMax: layerHeightMax,
            density: density,
            filamentDiameter: filamentDiameter,
            dryingTemp: dryingTemp,
            dryingTime: dryingTime,
            moistureSensitivity: moistureSensitivity
        )
    }
}
