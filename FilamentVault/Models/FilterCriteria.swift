import Foundation

struct FilterCriteria: Equatable {
    var materialTypes: Set<String> = []
    var brands: Set<String> = []
    var nozzleTempMin: Int? = nil
    var nozzleTempMax: Int? = nil
    var diameter: Double? = nil

    var isActive: Bool {
        !materialTypes.isEmpty ||
            !brands.isEmpty ||
            nozzleTempMin != nil ||
            nozzleTempMax != nil ||
            diameter != nil
    }

    func matches(_ f: Filament) -> Bool {
        if !materialTypes.isEmpty && !materialTypes.contains(f.materialType) {
            return false
        }
        if !brands.isEmpty {
            guard let b = f.brand, brands.contains(b) else { return false }
        }
        if let minT = nozzleTempMin {
            let range = (f.nozzleTempMin ?? 0)...(f.nozzleTempMax ?? Int.max)
            if !range.contains(minT) { return false }
        }
        if let maxT = nozzleTempMax {
            let range = (f.nozzleTempMin ?? 0)...(f.nozzleTempMax ?? Int.max)
            if !range.contains(maxT) { return false }
        }
        if let d = diameter, abs(f.filamentDiameter - d) > 0.01 {
            return false
        }
        return true
    }
}
