import SwiftUI
import UIKit

/// Tegels die continu en kalm van rechts naar links schuiven (marquee).
///
/// De doorlopende beweging draait via een `CADisplayLink` op een `UIScrollView`
/// (UIKit), níet via SwiftUI-state. Daardoor blijft de continue animatie buiten
/// SwiftUI's render-loop en breekt 'ie de tekst van het Regelen-scherm niet
/// (dat gebeurde wél met de eerdere SwiftUI/TimelineView-marquee). Tikken op een
/// tegel roept `onTap` aan.
struct MarqueeTilesView: UIViewRepresentable {
    let tiles: [SuggestionTile]
    var tileWidth: CGFloat = 150
    var spacing: CGFloat = 12
    /// Punten per frame (~0.4 ≈ 24 pt/s bij 60fps) — bewust kalm.
    var speed: CGFloat = 0.4
    /// Pauzeert de auto-scroll (bv. wanneer de Regelen-tab niet actief is).
    var paused: Bool = false
    let onTap: (SuggestionTile) -> Void

    func makeUIView(context: Context) -> MarqueeContainerView {
        let view = MarqueeContainerView()
        view.configure(tiles: tiles, tileWidth: tileWidth, spacing: spacing, speed: speed, onTap: onTap)
        return view
    }

    func updateUIView(_ uiView: MarqueeContainerView, context: Context) {
        uiView.setPaused(paused)
    }

    static func dismantleUIView(_ uiView: MarqueeContainerView, coordinator: ()) {
        uiView.stop()
    }
}

final class MarqueeContainerView: UIView, UIScrollViewDelegate {
    private let scroll = UIScrollView()
    private var hosting: UIHostingController<AnyView>?
    private var displayLink: CADisplayLink?
    private var oneSetWidth: CGFloat = 0
    private var speed: CGFloat = 0.4
    private var built = false
    /// Pauzeert de auto-scroll terwijl de gebruiker zelf sleept.
    private var userInteracting = false

    func configure(tiles: [SuggestionTile], tileWidth: CGFloat, spacing: CGFloat,
                   speed: CGFloat, onTap: @escaping (SuggestionTile) -> Void) {
        guard !built else { return }
        built = true
        self.speed = speed

        scroll.showsHorizontalScrollIndicator = false
        scroll.isScrollEnabled = true            // handmatig scrollen kan; auto-scroll loopt door
        scroll.delegate = self
        scroll.clipsToBounds = true
        scroll.backgroundColor = .clear
        addSubview(scroll)

        // Eén breedte van een volledige set tegels (incl. de spacing die volgt),
        // zodat we naadloos kunnen loopen op de gedupliceerde set.
        oneSetWidth = CGFloat(tiles.count) * (tileWidth + spacing)

        // Tegels dubbel zodat de loop naadloos is.
        let doubled = tiles + tiles
        let content = HStack(spacing: spacing) {
            ForEach(Array(doubled.enumerated()), id: \.offset) { _, tile in
                TegelView(
                    illustration: tile.illustration,
                    title: tile.title,
                    compact: true,
                    action: { onTap(tile) }
                )
                .frame(width: tileWidth)
            }
        }
        .padding(.leading, spacing)

        let host = UIHostingController(rootView: AnyView(content))
        host.view.backgroundColor = .clear
        hosting = host
        scroll.addSubview(host.view)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scroll.frame = bounds
        guard let host = hosting, oneSetWidth > 0 else { return }

        let totalWidth = oneSetWidth * 2
        host.view.frame = CGRect(x: 0, y: 0, width: totalWidth, height: bounds.height)
        scroll.contentSize = CGSize(width: totalWidth, height: bounds.height)

        if displayLink == nil {
            let link = CADisplayLink(target: self, selector: #selector(step))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
    }

    @objc private func step() {
        // Tijdens handmatig slepen niet auto-scrollen.
        guard oneSetWidth > 0, !userInteracting else { return }
        var x = scroll.contentOffset.x + speed
        if x >= oneSetWidth { x -= oneSetWidth }
        scroll.contentOffset.x = x
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        userInteracting = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { userInteracting = false }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        userInteracting = false
    }

    /// Houd de offset binnen één set, zodat de loop ook bij handmatig scrollen
    /// naadloos doorgaat (de tegels staan dubbel).
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard oneSetWidth > 0 else { return }
        var x = scrollView.contentOffset.x
        if x >= oneSetWidth { x -= oneSetWidth }
        else if x < 0 { x += oneSetWidth }
        if x != scrollView.contentOffset.x { scrollView.contentOffset.x = x }
    }

    /// Pauzeert/hervat de auto-scroll zonder de displayLink te vernietigen.
    func setPaused(_ p: Bool) {
        displayLink?.isPaused = p
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    deinit {
        displayLink?.invalidate()
    }
}
