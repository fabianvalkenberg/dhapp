import SwiftUI
import UIKit

/// Pulserend "radar"-effect rondom de huislocatie, gebruikt in `BuurtMapView`.
///
/// Bewust getekend via CoreAnimation (CAShapeLayer + CABasicAnimation) i.p.v.
/// een SwiftUI `repeatForever`-animatie: een doorlopende SwiftUI-animatie in
/// hetzelfde scherm als tekst kan die tekst onzichtbaar maken (zie het eerdere
/// Regelen-probleem). CoreAnimation draait op de render-server, los van
/// SwiftUI's layout-loop.
final class PulseHostView: UIView {
    private var ringLayers: [CAShapeLayer] = []
    private var pulseColor: UIColor = .systemGreen
    private var ringCount = 3
    private var duration: Double = 2.6
    private var started = false

    func configure(color: UIColor, ringCount: Int, duration: Double) {
        self.pulseColor = color
        self.ringCount = ringCount
        self.duration = duration
        for ring in ringLayers {
            ring.fillColor = color.withAlphaComponent(0.12).cgColor
            ring.strokeColor = color.withAlphaComponent(0.32).cgColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, !started else { return }
        started = true
        buildRings()
    }

    private func buildRings() {
        let diameter = min(bounds.width, bounds.height)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        for i in 0..<ringCount {
            let ring = CAShapeLayer()
            ring.frame = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            ring.path = UIBezierPath(ovalIn: ring.bounds).cgPath
            ring.position = center
            ring.fillColor = pulseColor.withAlphaComponent(0.12).cgColor
            ring.strokeColor = pulseColor.withAlphaComponent(0.32).cgColor
            ring.lineWidth = 1.5
            ring.opacity = 0
            layer.addSublayer(ring)
            ringLayers.append(ring)

            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 0.12
            scale.toValue = 1.0

            let opacity = CABasicAnimation(keyPath: "opacity")
            opacity.fromValue = 0.5
            opacity.toValue = 0.0

            let group = CAAnimationGroup()
            group.animations = [scale, opacity]
            group.duration = duration
            group.repeatCount = .infinity
            // Ringen gespreid in de tijd → continu uitdijende radar.
            group.beginTime = CACurrentMediaTime() + (Double(i) * duration / Double(ringCount))
            // Sterkere ease-out (easeOutExpo-achtig): snel uitdijen, lang zacht uitdoven.
            group.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)
            ring.add(group, forKey: "pulse")
        }
    }
}
