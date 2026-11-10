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
    private var sterk = false
    private var started = false

    private var fillAlpha: CGFloat = 0.12
    private var strokeAlpha: CGFloat = 0.32

    /// `sterk`: volle, levendige ringen voor de eigen locatie.
    func configure(color: UIColor, ringCount: Int, duration: Double, sterk: Bool = false) {
        self.pulseColor = color
        self.ringCount = ringCount
        self.duration = duration
        self.sterk = sterk
        fillAlpha = sterk ? 0.24 : 0.12
        strokeAlpha = sterk ? 0.9 : 0.32
        if started { herstart() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        // CoreAnimation gooit animaties weg als de app naar de achtergrond gaat;
        // bij terugkomst de radar opnieuw starten.
        NotificationCenter.default.addObserver(self, selector: #selector(herstart),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, !started else { return }
        started = true
        buildRings()
    }

    /// Na een tabwissel of het hergebruiken van de kaartmarker opnieuw starten.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, started { herstart() }
    }

    @objc private func herstart() {
        ringLayers.forEach { $0.removeFromSuperlayer() }
        ringLayers.removeAll()
        buildRings()
    }

    private func buildRings() {
        let diameter = min(bounds.width, bounds.height)
        guard diameter > 0 else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let nu = CACurrentMediaTime()

        for i in 0..<ringCount {
            let ring = CAShapeLayer()
            ring.frame = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            ring.path = UIBezierPath(ovalIn: ring.bounds).cgPath
            ring.position = center
            ring.fillColor = pulseColor.withAlphaComponent(fillAlpha).cgColor
            ring.strokeColor = pulseColor.withAlphaComponent(strokeAlpha).cgColor
            ring.lineWidth = sterk ? 2 : 1.5
            ring.opacity = 0
            layer.addSublayer(ring)
            ringLayers.append(ring)

            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = sterk ? 0.15 : 0.12
            scale.toValue = 1.0

            // Sterk: helder beginnen en pas in de laatste fase uitdoven, zodat je
            // de ring echt ziet uitdijen.
            let opacity = CAKeyframeAnimation(keyPath: "opacity")
            opacity.values = sterk ? [0.0, 1.0, 0.7, 0.0] : [0.5, 0.0]
            opacity.keyTimes = sterk ? [0, 0.08, 0.55, 1] : [0, 1]

            let group = CAAnimationGroup()
            group.animations = [scale, opacity]
            group.duration = duration
            group.repeatCount = .infinity
            group.isRemovedOnCompletion = false
            // Ringen gespreid in de tijd: een doorlopende radar.
            group.beginTime = nu + (Double(i) * duration / Double(ringCount))
            group.timingFunction = sterk
                ? CAMediaTimingFunction(controlPoints: 0.25, 0.6, 0.35, 1)
                : CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)
            ring.add(group, forKey: "pulse")
        }
    }
}
