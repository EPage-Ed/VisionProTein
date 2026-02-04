
import UIKit

public class RibbonColorScheme {
    public init() {}

    public func color(for type: SecondaryStructureType) -> UIColor {
        switch type {
        case .helix: return .systemRed
        case .sheet: return .systemBlue
        case .loop: return .systemGreen
        }
    }
}
