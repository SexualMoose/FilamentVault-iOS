import Foundation
import SwiftUI
import UIKit

enum ColorWheelSort {
    /// Sort filaments in traditional color-wheel order (red → orange → yellow →
    /// green → cyan → blue → magenta). Low-saturation colors (grays/black/white)
    /// cluster at the end, sorted by lightness.
    static func sorted(_ filaments: [Filament]) -> [Filament] {
        filaments.sorted { a, b in
            let ka = hsvKey(a.colorHex)
            let kb = hsvKey(b.colorHex)
            if ka.isGray != kb.isGray { return !ka.isGray }   // non-gray first
            if ka.hue != kb.hue { return ka.hue < kb.hue }
            if ka.saturation != kb.saturation { return ka.saturation > kb.saturation }
            return ka.lightness < kb.lightness
        }
    }

    struct HsvKey {
        let isGray: Bool
        let hue: CGFloat
        let saturation: CGFloat
        let lightness: CGFloat
    }

    static func hsvKey(_ hex: String) -> HsvKey {
        guard let uiColor = UIColor(hex: hex) else {
            return HsvKey(isGray: true, hue: 0, saturation: 0, lightness: 0.5)
        }
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &v, alpha: &a)
        return HsvKey(
            isGray: s < 0.12,
            hue: h * 360,
            saturation: s,
            lightness: v
        )
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6 || cleaned.count == 8 else { return nil }
        var rgb: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&rgb) else { return nil }
        let r, g, b, a: CGFloat
        if cleaned.count == 8 {
            a = CGFloat((rgb & 0xFF000000) >> 24) / 255
            r = CGFloat((rgb & 0x00FF0000) >> 16) / 255
            g = CGFloat((rgb & 0x0000FF00) >> 8) / 255
            b = CGFloat(rgb & 0x000000FF) / 255
        } else {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255
            b = CGFloat(rgb & 0x0000FF) / 255
            a = 1
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

extension Color {
    init(hex: String, fallback: Color = .gray) {
        if let uiColor = UIColor(hex: hex) {
            self = Color(uiColor: uiColor)
        } else {
            self = fallback
        }
    }
}
