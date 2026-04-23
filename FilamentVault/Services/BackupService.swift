import Foundation
import SwiftData
import UniformTypeIdentifiers

struct BackupBundle: Codable {
    var version: Int = 1
    var createdAt: Date = .now
    var filaments: [FilamentDto]
    var defaultOverrides: [DefaultOverrideDto]
}

struct FilamentDto: Codable {
    var materialType: String
    var colorHex: String
    var fillType: String?
    var colorName: String?
    var brand: String?
    var filamentDiameter: Double
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
    var dryingTemp: Int?
    var dryingTime: Int?
    var moistureSensitivity: String?
    var quantity: Int
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
}

struct DefaultOverrideDto: Codable {
    var baseMaterial: String?
    var baseBrand: String?
    var baseFillType: String?
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
    var filamentDiameter: Double
    var dryingTemp: Int?
    var dryingTime: Int?
    var moistureSensitivity: String?
    var updatedAt: Date
}

/// JSON wrapper that ships via SwiftUI's `.fileExporter` — iOS's Files app picker
/// natively shows iCloud Drive, Google Drive (if installed), OneDrive, Dropbox,
/// and local device storage, so the same code covers every backup destination.
struct BackupDocument: Codable {
    var bundle: BackupBundle
}

enum BackupService {

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    @MainActor
    static func export(context: ModelContext) throws -> Data {
        let filaments = (try context.fetch(FetchDescriptor<Filament>())).map { $0.toDto() }
        let overrides = (try context.fetch(FetchDescriptor<DefaultOverride>())).map { $0.toDto() }
        let bundle = BackupBundle(filaments: filaments, defaultOverrides: overrides)
        return try encoder.encode(bundle)
    }

    @MainActor
    static func importBundle(data: Data, context: ModelContext, replaceExisting: Bool) throws -> (Int, Int) {
        let bundle = try decoder.decode(BackupBundle.self, from: data)
        if replaceExisting {
            for f in try context.fetch(FetchDescriptor<Filament>()) {
                ImageStorage.delete(f.imageFilename)
                if let orig = f.originalImageFilename, orig != f.imageFilename {
                    ImageStorage.delete(orig)
                }
                context.delete(f)
            }
            for o in try context.fetch(FetchDescriptor<DefaultOverride>()) {
                context.delete(o)
            }
        }
        for dto in bundle.filaments {
            context.insert(dto.toEntity())
        }
        for dto in bundle.defaultOverrides {
            context.insert(dto.toEntity())
        }
        try context.save()
        return (bundle.filaments.count, bundle.defaultOverrides.count)
    }
}

// MARK: - DTO conversions

extension Filament {
    func toDto() -> FilamentDto {
        FilamentDto(
            materialType: materialType,
            colorHex: colorHex,
            fillType: fillType,
            colorName: colorName,
            brand: brand,
            filamentDiameter: filamentDiameter,
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
            dryingTemp: dryingTemp,
            dryingTime: dryingTime,
            moistureSensitivity: moistureSensitivity,
            quantity: quantity,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension FilamentDto {
    func toEntity() -> Filament {
        Filament(
            materialType: materialType,
            colorHex: colorHex,
            fillType: fillType,
            colorName: colorName,
            brand: brand,
            filamentDiameter: filamentDiameter,
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
            dryingTemp: dryingTemp,
            dryingTime: dryingTime,
            moistureSensitivity: moistureSensitivity,
            quantity: quantity,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension DefaultOverride {
    func toDto() -> DefaultOverrideDto {
        DefaultOverrideDto(
            baseMaterial: baseMaterial,
            baseBrand: baseBrand,
            baseFillType: baseFillType,
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
            moistureSensitivity: moistureSensitivity,
            updatedAt: updatedAt
        )
    }
}

extension DefaultOverrideDto {
    func toEntity() -> DefaultOverride {
        DefaultOverride(
            baseMaterial: baseMaterial,
            baseBrand: baseBrand,
            baseFillType: baseFillType,
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
            moistureSensitivity: moistureSensitivity,
            updatedAt: updatedAt
        )
    }
}
