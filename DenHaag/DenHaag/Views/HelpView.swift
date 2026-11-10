import SwiftUI

struct HelpView: View {
    @EnvironmentObject var lang: LanguageManager
    @State private var showFAQCategory: FAQCategory? = nil

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Page title
                    Text(lang.t("help_title"))
                        .font(AppFont.theMix(size: 26, weight: .bold))
                        .foregroundColor(Color(hex: "2D2D2D"))
                        .padding(.top, 16)

                    // Contact opties
                    ItemListView(items: [
                        ListItem(icon: "phone", title: lang.t("help_call_us")),
                        ListItem(icon: "chat", title: lang.t("help_chat_employee")),
                        ListItem(icon: "megaphone", title: lang.t("help_send_mail")),
                    ])

                    Spacer().frame(height: 8)

                    // Hulp in de buurt
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 6) {
                            Text(lang.t("help_nearby"))
                                .font(AppFont.theSans(size: 23, weight: .bold))
                                .foregroundColor(Color(hex: "2D2D2D"))

                            Image(systemName: "info.circle")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "2D2D2D"))
                        }

                        HelpLocationCarousel(lang: lang)
                    }

                    // Veelgestelde vragen
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lang.t("help_faq"))
                            .font(AppFont.theSans(size: 23, weight: .bold))
                            .foregroundColor(Color(hex: "2D2D2D"))

                        ItemListView(items: [
                            ListItem(icon: "icon-parking", title: lang.t("parking"), action: {
                                showFAQCategory = .parking
                            }),
                            ListItem(icon: "home", title: lang.t("help_living"), action: {
                                showFAQCategory = .living
                            }),
                            ListItem(icon: "icon-coin-euro", title: lang.t("help_money"), action: {
                                showFAQCategory = .money
                            }),
                        ])
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }

            // FAQ detail overlay
            if let category = showFAQCategory {
                HelpFAQView(category: category, isPresented: $showFAQCategory)
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showFAQCategory)
    }
}

// MARK: - Location Card for "Hulp in de buurt"

/// Hoe druk het is aan de balie.
enum BusyLevel {
    case rustig, gemiddeld, druk
    var label: String {
        switch self {
        case .rustig:    return "Rustig aan de balie"
        case .gemiddeld: return "Gemiddeld druk"
        case .druk:      return "Druk aan de balie"
        }
    }
    var color: Color {
        switch self {
        case .rustig:    return AppColors.groen3
        case .gemiddeld: return Color(hex: "E59500")
        case .druk:      return AppColors.rood
        }
    }
    var filledBars: Int {
        switch self {
        case .rustig: return 1
        case .gemiddeld: return 2
        case .druk: return 3
        }
    }
}

struct HelpLocationCard: View {
    @EnvironmentObject var versie: VersieManager
    let name: String
    let hours: String
    let imageName: String
    let busy: BusyLevel
    let openLabel: String
    let closedLabel: String
    let items: [ListItem]

    /// Open/dicht wordt op de huidige tijd berekend i.p.v. hardgecodeerd.
    private var isOpen: Bool { HelpLocationCard.isOpenNow(hours) }
    private var statusLabel: String { isOpen ? openLabel : closedLabel }

    /// "08:00 - 21:00" → open als de huidige tijd binnen het bereik valt.
    static func isOpenNow(_ hours: String) -> Bool {
        let parts = hours.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, let open = minutes(parts[0]), let close = minutes(parts[1]) else { return false }
        let cal = Calendar.current
        let now = cal.component(.hour, from: Date()) * 60 + cal.component(.minute, from: Date())
        return now >= open && now < close
    }
    private static func minutes(_ s: String) -> Int? {
        let hm = s.split(separator: ":")
        guard hm.count == 2, let h = Int(hm[0]), let m = Int(hm[1]) else { return nil }
        return h * 60 + m
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Location name
            Text(name)
                .font(AppFont.theMix(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "2D2D2D"))

            // Status + hours
            HStack(spacing: 4) {
                Circle()
                    .fill(isOpen ? AppColors.groen3 : AppColors.rood)
                    .frame(width: 10, height: 10)

                Text(statusLabel)
                    .font(AppFont.theSans(size: 12, weight: .bold))
                    .foregroundColor(isOpen ? AppColors.groen3 : AppColors.rood)
                    .textCase(.uppercase)
                    .tracking(1)

                Rectangle()
                    .fill(AppColors.grijs2)
                    .frame(width: 1, height: 14)
                    .padding(.horizontal, 4)

                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)

                Text(hours)
                    .font(AppFont.theSans(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }

            // Drukte-indicator bij de balie (3 oplopende staafjes + label).
            // Hoort bij afspraken en het loket; zit dus niet in versie 1.
            if versie.current.heeft(.afspraken) {
            HStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(i < busy.filledBars ? busy.color : AppColors.grijs2)
                            .frame(width: 4, height: 7 + CGFloat(i) * 4)
                    }
                }
                Text(busy.label)
                    .font(AppFont.theSans(size: 13, weight: .semiBold))
                    .foregroundColor(busy.color)
            }
            }

            // Foto van het kantoor (valt terug op een grijze placeholder zolang
            // het beeld nog niet als asset is toegevoegd).
            Group {
                if UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(hex: "E0DDD8")
                        .overlay(
                            Image(systemName: "building.2")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.grijs2)
                        )
                }
            }
            .frame(height: 167)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Action items
            ItemListView(items: items)
        }
        .padding(16)
        .padding(.vertical, 8)
        .background(AppColors.warmGrijs)
        .cornerRadius(AppDesign.cornerRadius)
    }
}

// MARK: - Horizontal Location Carousel

struct HelpLocationCarousel: View {
    let lang: LanguageManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Stadhuis Spui
                HelpLocationCard(
                    name: lang.t("help_stadhuis_spui"),
                    hours: "08:00 - 21:00",
                    imageName: "stadhuis-spui",
                    busy: .druk,
                    openLabel: lang.t("help_now_open"),
                    closedLabel: lang.t("help_now_closed"),
                    items: [
                        ListItem(icon: "calendar", title: lang.t("help_make_appointment")),
                        ListItem(icon: "calendar", title: lang.t("help_opening_hours")),
                        ListItem(icon: "location-pin", title: lang.t("help_plan_route"), isSystemIcon: false),
                    ]
                )
                .frame(width: 330)

                // Stadsdeelkantoor Scheveningen
                HelpLocationCard(
                    name: lang.t("help_scheveningen"),
                    hours: "09:00 - 17:00",
                    imageName: "scheveningen",
                    busy: .rustig,
                    openLabel: lang.t("help_now_open"),
                    closedLabel: lang.t("help_now_closed"),
                    items: [
                        ListItem(icon: "calendar", title: lang.t("help_make_appointment")),
                        ListItem(icon: "calendar", title: lang.t("help_opening_hours")),
                        ListItem(icon: "location-pin", title: lang.t("help_plan_route"), isSystemIcon: false),
                    ]
                )
                .frame(width: 330)

                // Stadsdeelkantoor Escamp
                HelpLocationCard(
                    name: lang.t("help_escamp"),
                    hours: "08:30 - 16:00",
                    imageName: "escamp",
                    busy: .gemiddeld,
                    openLabel: lang.t("help_now_open"),
                    closedLabel: lang.t("help_now_closed"),
                    items: [
                        ListItem(icon: "calendar", title: lang.t("help_make_appointment")),
                        ListItem(icon: "calendar", title: lang.t("help_opening_hours")),
                        ListItem(icon: "location-pin", title: lang.t("help_plan_route"), isSystemIcon: false),
                    ]
                )
                .frame(width: 330)
            }
        }
    }
}
