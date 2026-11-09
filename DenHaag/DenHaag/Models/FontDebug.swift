import UIKit

struct FontDebug {
    static func printAllFonts() {
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            if family.lowercased().contains("thesans") || family.lowercased().contains("themix") {
                print("Family: \(family)")
                for name in names {
                    print("  - \(name)")
                }
            }
        }
    }
}
