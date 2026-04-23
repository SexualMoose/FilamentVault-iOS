import Foundation
import SwiftData

@Model
final class Filament {
    // Required identity
    var materialType: String
    var colorHex: String

    // Optional identity
    var fillType: String?
    var colorName: String?
    var brand: String?
    var filamentDiameter: Double

    // Temperature settings
    var nozzleTempMin: Int?
    var nozzleTempMax: Int?
    var bedTempMin: Int?
    var bedTempMax: Int?
    var chamberTemp: Int?

    // Speed settings
    var printSpeedMin: Int?
    var printSpeedMax: Int?
    var maxVolumetricSpeed: Double?
    var fanSpeedMin: Int?
    var fanSpeedMax: Int?
    var fanSpeedNotes: String?

    // Retraction + extrusion
    var retractionDistance: Double?
    var retractionSpeed: Double?
    var flowRate: Double?
    var layerHeightMin: Double?
    var layerHeightMax: Double?

    // Physical
    var density: Double?

    // Drying / moisture
    var dryingTemp: Int?
    var dryingTime: Int?
    var moistureSensitivity: String?

    // Inventory
    var quantity: Int

    // User content
    var notes: String?
    var imageFilename: String?          // relative path under app documents/filament_images/
    var originalImageFilename: String?  // the un-cropped source (for re-crop)

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    init(
        materialType: String,
        colorHex: String,
        fillType: String? = nil,
        colorName: String? = nil,
        brand: String? = nil,
        filamentDiameter: Double = 1.75,
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
        dryingTemp: Int? = nil,
        dryingTime: Int? = nil,
        moistureSensitivity: String? = nil,
        quantity: Int = 1,
        notes: String? = nil,
        imageFilename: String? = nil,
        originalImageFilename: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.materialType = materialType
        self.colorHex = colorHex
        self.fillType = fillType
        self.colorName = colorName
        self.brand = brand
        self.filamentDiameter = filamentDiameter
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
        self.dryingTemp = dryingTemp
        self.dryingTime = dryingTime
        self.moistureSensitivity = moistureSensitivity
        self.quantity = quantity
        self.notes = notes
        self.imageFilename = imageFilename
        self.originalImageFilename = originalImageFilename
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
