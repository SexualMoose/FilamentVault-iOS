import SwiftUI

struct FilamentCardView: View {
    let filament: Filament

    var body: some View {
        HStack(spacing: 16) {
            ColorSwatchSpool(colorHex: filament.colorHex, size: 72)

            VStack(alignment: .leading, spacing: 2) {
                Text(filament.materialType)
                    .font(.headline)
                    .bold()

                let subtitle = [filament.brand, filament.fillType]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty && $0 != "Standard" }
                    .joined(separator: " · ")
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if let name = filament.colorName {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Qty: \(filament.quantity)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(
                            filament.quantity > 1 ? Color.blue : .secondary
                        )
                }

                if hasTemps {
                    Text(tempInfo)
                        .font(.caption2)
                        .foregroundStyle(Color.blue.opacity(0.85))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(height: 108)
        .background(Color(white: 0.07))
        .clipShape(RoundedCornerShape(radius: 12))
    }

    private var hasTemps: Bool {
        filament.nozzleTempMin != nil || filament.nozzleTempMax != nil ||
        filament.bedTempMin != nil || filament.bedTempMax != nil
    }

    private var tempInfo: String {
        var parts: [String] = []
        if filament.nozzleTempMin != nil || filament.nozzleTempMax != nil {
            parts.append("Nozzle \(range(filament.nozzleTempMin, filament.nozzleTempMax))")
        }
        if filament.bedTempMin != nil || filament.bedTempMax != nil {
            parts.append("Bed \(range(filament.bedTempMin, filament.bedTempMax))")
        }
        return parts.joined(separator: "  ·  ")
    }

    private func range(_ min: Int?, _ max: Int?) -> String {
        switch (min, max) {
        case let (a?, b?) where a != b: return "\(a)-\(b)°C"
        case let (a?, _): return "\(a)°C"
        case let (_, b?): return "\(b)°C"
        default: return ""
        }
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: radius)
    }
}
