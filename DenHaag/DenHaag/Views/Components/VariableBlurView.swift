import SwiftUI
import UIKit

/// Progressieve ("variable") backdrop-blur: sterk aan één rand, vloeiend
/// uitlopend naar transparant. Content áchter de view verzacht zo geleidelijk
/// naar een sticky header toe.
///
/// Bewust met **alleen publieke API**: een standaard `UIVisualEffectView` met een
/// `CAGradientLayer`-masker dat de blur naar de andere rand laat uitvloeien.
/// (Eerdere versie gebruikte de private `CAFilter("variableBlur")`; die kon bij het
/// snapshotten van de UI tijdens het naar de achtergrond gaan — scherm uit — de app
/// laten crashen. Daarom vervangen.)
struct VariableBlurView: UIViewRepresentable {
    /// Richting waarin de blur het sterkst is.
    enum Edge { case top, bottom }

    var maxBlurRadius: CGFloat = 18
    var edge: Edge = .top

    func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(edge: edge)
    }

    func updateUIView(_ uiView: VariableBlurUIView, context: Context) {}
}

final class VariableBlurUIView: UIVisualEffectView {
    private let edge: VariableBlurView.Edge
    private let gradientMask = CAGradientLayer()

    init(edge: VariableBlurView.Edge) {
        self.edge = edge
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        isUserInteractionEnabled = false

        // Masker: zwart (= blur zichtbaar) aan de gekozen rand → transparant
        // (= geen blur) aan de andere kant. Zo vloeit de blur geleidelijk uit.
        gradientMask.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        gradientMask.locations = [0.0, 1.0]
        gradientMask.startPoint = CGPoint(x: 0.5, y: edge == .top ? 0.0 : 1.0)
        gradientMask.endPoint = CGPoint(x: 0.5, y: edge == .top ? 1.0 : 0.0)
        layer.mask = gradientMask
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientMask.frame = bounds
    }
}
