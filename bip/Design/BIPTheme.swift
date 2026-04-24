import SwiftUI

enum BIPTheme {
    static let background = Color(red: 0.13, green: 0.13, blue: 0.13)
    static let elevated = Color(red: 0.24, green: 0.24, blue: 0.24)
    static let elevatedLight = Color(red: 0.32, green: 0.32, blue: 0.32)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.64, green: 0.64, blue: 0.64)
    static let muted = Color(red: 0.45, green: 0.45, blue: 0.45)
    static let success = Color(red: 0.36, green: 0.78, blue: 0.45)
    static let sheetBackground = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let sheetField = Color(red: 0.18, green: 0.18, blue: 0.18)
    static let sheetFieldLight = Color(red: 0.27, green: 0.27, blue: 0.27)
    static let sheetStroke = Color.white.opacity(0.10)
    static let warmAccent = Color(red: 0.60, green: 0.32, blue: 0.07)
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch cleaned.count {
        case 6:
            red = (value >> 16) & 0xff
            green = (value >> 8) & 0xff
            blue = value & 0xff
        default:
            red = 0x99
            green = 0x99
            blue = 0x99
        }

        self.init(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}
