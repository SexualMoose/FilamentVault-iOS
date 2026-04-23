import Foundation
import SwiftData

/// Built-in filament default — seeded from defaults.json on first launch.
/// Read-only from the UI. User edits are layered on top via DefaultOverride.
@Model
final class DefaultSetting {
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

    init(
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
        moistureSensitivity: String? = nil
    ) {
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
    }
}
