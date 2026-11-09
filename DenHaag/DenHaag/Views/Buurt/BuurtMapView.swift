import SwiftUI
import MapKit

// MARK: - Annotaties

final class ItemAnnotation: NSObject, MKAnnotation {
    let id: UUID
    let type: NeighbourhoodItem.ItemType
    let coordinate: CLLocationCoordinate2D
    init(_ item: NeighbourhoodItem) {
        id = item.id
        type = item.type
        coordinate = item.coordinate
    }
}

final class HomeAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    init(_ c: CLLocationCoordinate2D) { coordinate = c }
}

/// CARTO Positron tile-overlay die de aanvragen over de subdomeinen a/b/c/d
/// spreidt. Eén host throttelt (parallel-verbindingen per host), waardoor
/// tegels traag of onvolledig laadden; spreiden laadt de kaart sneller én vol.
///
/// Sinds 23-09-2026 eist CARTO een API-key. Zonder key komen de tegels nog wel
/// binnen (HTTP 200), maar met "API KEY REQUIRED" dwars over de kaart gestempeld
/// — erger dan geen tegels. Daarom bouwen we de overlay alleen als er een key
/// is; zonder key toont de kaart Apple's eigen (muted) basemap.
final class CartoTileOverlay: MKTileOverlay {
    private static let subdomains = ["a", "b", "c", "d"]
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let s = Self.subdomains[abs(path.x &+ path.y) % Self.subdomains.count]
        let str = "https://\(s).basemaps.cartocdn.com/light_nolabels/\(path.z)/\(path.x)/\(path.y)@2x.png"
            + "?key=\(APIConfig.cartoAPIKey)"
        return URL(string: str)!
    }

    /// nil = geen (bruikbare) CARTO-tegels beschikbaar.
    static func makeIfAvailable() -> CartoTileOverlay? {
        guard !APIConfig.cartoAPIKey.isEmpty else { return nil }
        let overlay = CartoTileOverlay(urlTemplate: nil)
        // false = de (muted, POI-loze) Apple-basemap blijft eronder als vangnet:
        // laden de CARTO-tegels traag of niet (slecht wifi tijdens demo), dan zie
        // je nog steeds een kaart i.p.v. een leeg vlak. Zodra CARTO laadt, dekt die
        // de Apple-kaart volledig af.
        overlay.canReplaceMapContent = false
        overlay.tileSize = CGSize(width: 512, height: 512)
        return overlay
    }
}

// MARK: - Minimale, label-loze kaart (CARTO Positron) met custom pins + huis-radar

/// MKMapView met een CARTO Positron "no-labels" tile-overlay, zodat de kaart
/// licht en minimaal is en géén straatnamen toont (wat Apple Maps niet kan).
/// Tegels komen van een externe dienst (CARTO/OpenStreetMap) — bewuste keuze
/// voor de demo. Pins en de pulserende huislocatie worden custom getekend.
struct BuurtMapView: UIViewRepresentable {
    var items: [NeighbourhoodItem]
    var homeCoordinate: CLLocationCoordinate2D
    @Binding var selectedItemID: UUID?
    var region: MKCoordinateRegion
    /// Bumpt bij elke programmatische camerawijziging; zo zetten we de regio
    /// alleen dán, en vechten we niet met het pannen/zoomen van de gebruiker.
    var regionVersion: Int

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.pointOfInterestFilter = .excludingAll
        map.showsCompass = false
        map.showsScale = false
        map.showsTraffic = false
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.overrideUserInterfaceStyle = .light

        // Apple-basemap zo dicht mogelijk bij de Positron-look: vlak (geen 3D),
        // gedempte kleuren en geen POI-pins. Dit is de kaart die je ziet als er
        // geen CARTO-key is, en anders het vangnet eronder.
        let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        config.pointOfInterestFilter = .excludingAll
        map.preferredConfiguration = config

        if let overlay = CartoTileOverlay.makeIfAvailable() {
            map.addOverlay(overlay, level: .aboveLabels)
        }

        map.setRegion(region, animated: false)
        context.coordinator.lastVersion = regionVersion

        map.addAnnotation(HomeAnnotation(homeCoordinate))
        context.coordinator.syncItems(map: map, items: items)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        if regionVersion != context.coordinator.lastVersion {
            context.coordinator.lastVersion = regionVersion
            // Rustige ease-out naar de marker, maar wat vlotter dan voorheen.
            UIView.animate(withDuration: 0.9, delay: 0,
                           options: [.curveEaseOut, .beginFromCurrentState]) {
                map.region = region
            }
        }

        if let home = map.annotations.compactMap({ $0 as? HomeAnnotation }).first,
           home.coordinate.latitude != homeCoordinate.latitude
            || home.coordinate.longitude != homeCoordinate.longitude {
            map.removeAnnotation(home)
            map.addAnnotation(HomeAnnotation(homeCoordinate))
        }

        context.coordinator.syncItems(map: map, items: items)
        context.coordinator.updateSelection(map: map, selectedID: selectedItemID)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: BuurtMapView
        var lastVersion: Int = -1
        var lastSelectedID: UUID?
        /// Cache van de gerenderde pin-afbeeldingen (3 types × 2 states = 6 stuks),
        /// zodat we niet bij elke selectie/camera-update alle pins opnieuw rasteren.
        static var pinCache: [String: UIImage] = [:]
        init(_ p: BuurtMapView) { parent = p }

        func syncItems(map: MKMapView, items: [NeighbourhoodItem]) {
            let existing = map.annotations.compactMap { $0 as? ItemAnnotation }
            let newIDs = Set(items.map { $0.id })
            let existingIDs = Set(existing.map { $0.id })
            for a in existing where !newIDs.contains(a.id) { map.removeAnnotation(a) }
            for item in items where !existingIDs.contains(item.id) { map.addAnnotation(ItemAnnotation(item)) }
        }

        func updateSelection(map: MKMapView, selectedID: UUID?) {
            let changed = selectedID != lastSelectedID
            for a in map.annotations.compactMap({ $0 as? ItemAnnotation }) {
                if let v = map.view(for: a) {
                    applyItemImage(v, type: a.type, selected: a.id == selectedID)
                    // Subtiel speels bounce-effect op de net-geselecteerde marker.
                    if changed, a.id == selectedID {
                        v.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                        UIView.animate(withDuration: 0.5, delay: 0,
                                       usingSpringWithDamping: 0.52, initialSpringVelocity: 0.4,
                                       options: [.allowUserInteraction, .beginFromCurrentState]) {
                            v.transform = .identity
                        }
                    }
                }
            }
            lastSelectedID = selectedID
        }

        // MARK: MKMapViewDelegate

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tile = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tile)
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is HomeAnnotation {
                let id = "home"
                let v = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
                v.annotation = annotation
                v.canShowCallout = false
                v.isEnabled = false
                v.subviews.forEach { $0.removeFromSuperview() }

                let size: CGFloat = 150
                let container = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
                container.isUserInteractionEnabled = false

                // Rustige pulserende radar markeert de thuislocatie; nog kalmer
                // (langere duur + sterkere ease-out) dan voorheen.
                let radar = PulseHostView(frame: container.bounds)
                radar.backgroundColor = .clear
                radar.configure(color: UIColor(AppColors.groen3), ringCount: 3, duration: 6.5)
                container.addSubview(radar)

                // Vast groen stipje in het midden: dít is jouw (thuis)locatie.
                let dotSize: CGFloat = 16
                let dot = UIView(frame: CGRect(x: (size - dotSize) / 2, y: (size - dotSize) / 2,
                                               width: dotSize, height: dotSize))
                dot.backgroundColor = UIColor(AppColors.groen3)
                dot.layer.cornerRadius = dotSize / 2
                dot.layer.borderColor = UIColor.white.cgColor
                dot.layer.borderWidth = 2.5
                dot.layer.shadowColor = UIColor.black.cgColor
                dot.layer.shadowOpacity = 0.25
                dot.layer.shadowRadius = 2
                dot.layer.shadowOffset = CGSize(width: 0, height: 1)
                dot.isUserInteractionEnabled = false
                container.addSubview(dot)

                v.frame = container.bounds
                v.addSubview(container)
                v.centerOffset = .zero
                return v
            }

            if let item = annotation as? ItemAnnotation {
                let id = "item"
                let v = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? ItemPinView)
                    ?? ItemPinView(annotation: annotation, reuseIdentifier: id)
                v.annotation = annotation
                v.canShowCallout = false
                applyItemImage(v, type: item.type, selected: item.id == parent.selectedItemID)
                return v
            }
            return nil
        }

        func applyItemImage(_ v: MKAnnotationView, type: NeighbourhoodItem.ItemType, selected: Bool) {
            let key = "\(type.markerIcon)-\(selected)"
            let cached: UIImage?
            if let hit = Self.pinCache[key] {
                cached = hit
            } else {
                let fill = selected ? AppColors.groen3 : AppColors.geel3
                let iconColor: Color = selected ? .white : AppColors.darkGrey
                cached = Self.pinImage(fill: fill, icon: type.markerIcon, iconColor: iconColor,
                                       scale: selected ? 1.5 : 1.0)
                if let cached { Self.pinCache[key] = cached }
            }
            if let img = cached {
                v.image = img
                v.centerOffset = CGPoint(x: 0, y: -img.size.height / 2)
                // Geselecteerde marker altijd bovenop de gele markers. zPosition wordt
                // door MapKit per layout hersorteerd, dus ItemPinView herhaalt 'm.
                v.layer.zPosition = selected ? 1000 : 0
                (v as? ItemPinView)?.keepInFront = selected
            }
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let item = view.annotation as? ItemAnnotation {
                parent.selectedItemID = item.id
                mapView.deselectAnnotation(view.annotation, animated: false)
            }
        }

        @MainActor
        static func pinImage(fill: Color, icon: String, iconColor: Color, scale: CGFloat = 1.0) -> UIImage? {
            let glyph = PinGlyph(fill: fill, icon: icon, iconColor: iconColor).scaleEffect(scale)
            let renderer = ImageRenderer(content: glyph.frame(width: 44 * scale, height: 54 * scale))
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage
        }
    }
}

// MARK: - Item-pin-view die de geselecteerde marker vooraan houdt

/// MapKit hersorteert annotatie-views per layout op breedtegraad, waardoor een
/// zuidelijker (lager op het scherm) gele marker vóór de geselecteerde groene kan
/// komen. Door de zPosition in `layoutSubviews` te herhalen, blijft de
/// geselecteerde marker altijd bovenop.
final class ItemPinView: MKAnnotationView {
    var keepInFront = false

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.zPosition = keepInFront ? 1000 : 0
    }
}

// MARK: - Statische teardrop-pin (voor ImageRenderer)

private struct PinGlyph: View {
    let fill: Color
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: -3) {
            ZStack {
                Circle()
                    .fill(fill)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 2)
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 19, height: 19)
                    .foregroundColor(iconColor)
            }
            PinTriangle()
                .fill(fill)
                .frame(width: 14, height: 9)
        }
        .frame(width: 44, height: 54)
    }
}
