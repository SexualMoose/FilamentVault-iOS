import Foundation

enum MaterialType: String, CaseIterable, Identifiable {
    case pla = "PLA"
    case abs = "ABS"
    case petg = "PETG"
    case tpu = "TPU"
    case nylon = "Nylon"
    case asa = "ASA"
    case pc = "PC"
    case pctg = "PCTG"
    case hips = "HIPS"
    case pva = "PVA"
    case pp = "PP"
    case pei = "PEI/ULTEM"
    case cfNylon = "CF Nylon"
    case cfPetg = "CF PETG"
    case peek = "PEEK"
    case pom = "POM"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

/// Material modifier. Named FillType for data compatibility with the Android
/// codebase; displayed as "Modifier" in the UI.
enum FillType: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case plus = "Plus (+)"
    case pro = "Pro"
    case highSpeed = "High Speed (HS)"
    case tough = "Tough/Impact"
    case air = "Air/LW (Foaming)"
    case crystal = "Crystal/Clear"
    case silk = "Silk"
    case matte = "Matte"
    case marble = "Marble"
    case gradient = "Gradient/Multicolor"
    case glowInDark = "Glow-in-Dark"
    case carbonFiber = "Carbon Fiber"
    case glassFiber = "Glass Fiber"
    case woodFill = "Wood Fill"
    case metalFill = "Metal Fill"
    case galaxy = "Galaxy/Sparkle"
    case translucent = "Translucent"

    var id: String { rawValue }
    var displayName: String { rawValue }
}
