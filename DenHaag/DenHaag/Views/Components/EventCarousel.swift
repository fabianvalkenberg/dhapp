import SwiftUI

// MARK: - Card Category

enum EventCategory {
    case community    // Buurt- en vrijwilligerswerk
    case participatie // Meedenken / inspraak
    case melding      // Werkzaamheden, omleidingen
    case cultuur      // Evenementen, cultuur

    var backgroundColor: Color {
        switch self {
        case .community:   return Color(hex: "E8F5E9")
        case .participatie: return Color(hex: "E3F2FD")
        case .melding:     return Color(hex: "FFF3E0")
        case .cultuur:     return Color(hex: "FFF7D1")
        }
    }

    var accentColor: Color {
        switch self {
        case .community:   return AppColors.groen3
        case .participatie: return AppColors.blauw3
        case .melding:     return Color(hex: "E65100")
        case .cultuur:     return Color(hex: "C6A700")
        }
    }

    var labelKey: String {
        switch self {
        case .community:   return "volunteer"
        case .participatie: return "participate"
        case .melding:     return "in_your_area"
        case .cultuur:     return "event"
        }
    }
}

// MARK: - Model

struct EventItem: Identifiable {
    let id = UUID()
    let titleKey: String
    let descriptionKey: String
    let time: String
    let location: String
    let month: String
    let day: String
    let weekday: String
    let category: EventCategory
    let imageName: String?

    static let sampleEvents: [EventItem] = [
        EventItem(
            titleKey: "event_beach_title",
            descriptionKey: "event_beach_desc",
            time: "09.00 - 12.00",
            location: "Het Spui",
            month: "NOV",
            day: "12",
            weekday: "di",
            category: .community,
            imageName: "beach-cleanup"
        ),
        EventItem(
            titleKey: "event_playground_title",
            descriptionKey: "event_playground_desc",
            time: "15.00 - 17.00",
            location: "Buurthuis De Paardenberg",
            month: "JAN",
            day: "25",
            weekday: "za",
            category: .participatie,
            imageName: "speeltuin"
        ),
        EventItem(
            titleKey: "event_roadworks_title",
            descriptionKey: "event_roadworks_desc",
            time: "07.00 - 19.00",
            location: "Laan van Meerdervoort",
            month: "FEB",
            day: "3",
            weekday: "ma",
            category: .melding,
            imageName: "wegwerkzaamheden"
        ),
        EventItem(
            titleKey: "event_binnenhof_title",
            descriptionKey: "event_binnenhof_desc",
            time: "11.00 - 13.00",
            location: "Binnenhof",
            month: "FEB",
            day: "15",
            weekday: "za",
            category: .cultuur,
            imageName: "binnenhof"
        ),
        EventItem(
            titleKey: "event_garden_title",
            descriptionKey: "event_garden_desc",
            time: "10.00 - 14.00",
            location: "Braakliggend terrein Jupiterstraat",
            month: "MRT",
            day: "8",
            weekday: "za",
            category: .community,
            imageName: nil
        ),
    ]
}

// MARK: - Carousel

struct EventCarousel: View {
    @EnvironmentObject var lang: LanguageManager
    let events = EventItem.sampleEvents
    @State private var currentIndex = 0
    var onEventTapped: ((EventItem) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Text(lang.t("chosen_for_you"))
                        .font(AppFont.theMix(size: 22, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Button(lang.t("view_all")) {
                    // Show all
                }
                .font(AppFont.theSans(size: 16, weight: .semiBold))
                .foregroundColor(AppColors.blauw3)
            }
            .padding(.horizontal, AppDesign.horizontalPadding)

            // Cards - using TabView for smooth native swiping
            TabView(selection: $currentIndex) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    EventCard(event: event)
                        .padding(.horizontal, AppDesign.horizontalPadding)
                        .tag(index)
                        .onTapGesture {
                            onEventTapped?(event)
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 340)

            // Page indicators
            HStack(spacing: 6) {
                ForEach(0..<events.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentIndex ? AppColors.groen3 : AppColors.groen3.opacity(0.3))
                        .frame(width: index == currentIndex ? 16 : 6, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Card

// MARK: - Date Badge (calendar block from Figma)

struct DateBadge: View {
    let month: String
    let day: String
    let weekday: String

    var body: some View {
        VStack(spacing: 0) {
            // Green month header
            Text(month)
                .font(AppFont.theSans(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "1D6B34"))
                .tracking(1)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(Color(hex: "D5E7D4"))

            // White day + weekday
            VStack(spacing: -4) {
                Text(day)
                    .font(AppFont.theMix(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))

                Text(weekday)
                    .font(AppFont.theSans(size: 18, weight: .plain))
                    .foregroundColor(Color(hex: "7A7A7A"))
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 6)
            .background(Color.white)
        }
        .frame(width: 64)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 0, x: 0, y: 0)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .inset(by: -0.5)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Event Card (Figma design)

struct EventCard: View {
    @EnvironmentObject var lang: LanguageManager
    let event: EventItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: image with date badge
            ZStack(alignment: .topLeading) {
                if let imageName = event.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipped()
                } else {
                    event.category.backgroundColor
                        .frame(height: 140)
                }

                // Date badge
                DateBadge(month: event.month, day: event.day, weekday: event.weekday)
                    .padding(24)
            }
            .clipped()

            // Base: content
            VStack(alignment: .leading, spacing: 20) {
                // Title + description
                VStack(alignment: .leading, spacing: 8) {
                    Text(lang.t(event.titleKey))
                        .font(AppFont.theSans(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .lineSpacing(2)

                    Text(lang.t(event.descriptionKey))
                        .font(AppFont.theSans(size: 18, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .lineSpacing(2)
                }

                // Details: location + time with chevron
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Location
                        HStack(spacing: 4) {
                            Image("location-pin")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text(event.location)
                                .font(AppFont.theSans(size: 14, weight: .plain))
                                .lineLimit(1)
                        }

                        // Time
                        HStack(spacing: 4) {
                            Image("calendar")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text(event.time)
                                .font(AppFont.theSans(size: 14, weight: .plain))
                                .lineLimit(1)
                        }
                    }
                    .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    // Chevron right
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.blauw3)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 24)
            .padding(.horizontal, 24)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(AppColors.grijs2, lineWidth: 1)
        )
    }
}
