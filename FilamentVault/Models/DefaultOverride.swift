import Foundation
import SwiftData

/// User edit layered on top of a built-in DefaultSetting, OR a user-created
/// new default (when baseId is nil). This table lets the user modify the
/// built-in catalog without destroying the factory values.
@Model
final class DefaultOverride {
    /// Persistent-model identifier of the built-in DefaultSetting this override
    /// replaces. Nil = this is a user-created new default.
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

    /// True when this override replaces a built-in entry. False = user-created new.
    var isOverride: Bool {
        baseMaterial != nil
    }

    init(
        baseMaterial: String? = nil,
        baseBrand: String? = nil,
        baseFillType: String? = nil,
        materialType: String,
        brand: String? = nil,
        fillType: String? = nil,
        nozzleTempMin: Int? = nil,
        nozzleTempMax: Int? = nil,
        bedTempMin: Int? = nil,
        bedTempMax: Int? = nil,
        chamberTemp: Int? = nil,
        printSpeedMin: Int? = nil,
        printSpeedMax: Int? = nil,
        maxVolumetricSpeed: Double? = nil,
        fanSpeedMin: Int? = nil,
        fanSpeedMax: Int? = nil,
        fanSpeedNotes: String? = nil,
        retractionDistance: Double? = nil,
        retractionSpeed: Double? = nil,
        flowRate: Double? = nil,
        layerHeightMin: Double? = nil,
        layerHeightMax: Double? = nil,
        density: Double? = nil,
        filamentDiameter: Double = 1.75,
        dryingTemp: Int? = nil,
        dryingTime: Int? = nil,
        moistureSensitivity: String? = nil,
        updatedAt: Date = .now
    ) {
        self.baseMaterial = baseMaterial
        self.baseBrand = baseBrand
        self.baseFillType = baseFillType
        self.materialType = materialType
        self.brand = brand
        self.fillType = fillType
        self.nozzleTempMin = nozzleTempMin
        self.nozzleTempMax = nozzleTempMax
        self.bedTempMin = bedTempMin
        self.bedTempMax = bedTempMax
        self.chamberTemp = chamberTemp
        self.printSpeedMin = printSpeedMin
        self.printSpeedMax = printSpeedMax
        self.maxVolumetricSpeed = maxVolumetricSpeed
        self.fanSpeedMin = fanSpeedMin
        self.fanSpeedMax = fanSpeedMax
        self.fanSpeedNotes = fanSpeedNotes
        self.retractionDistance = retractionDistance
        self.retractionSpeed = retractionSpeed
        self.flowRate = flowRate
        self.layerHeightMin = layerHeightMin
        self.layerHeightMax = layerHeightMax
        self.density = density
        self.filamentDiameter = filamentDiameter
        self.dryingTemp = dryingTemp
        self.dryingTime = dryingTime
        self.moistureSensitivity = moistureSensitivity
        self.updatedAt = updatedAt
    }
}
