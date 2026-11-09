import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var lang: LanguageManager
    let event: EventItem
    @Binding var isPresented: Bool

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero image or colored header
                    ZStack(alignment: .bottomLeading) {
                        if let imageName = event.imageName {
                            GeometryReader { geo in
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width, height: 260 + safeTop)
                                    .clipped()
                            }
                            .frame(height: 260 + safeTop)
                            .overlay(
                                LinearGradient(
                                    colors: [.black.opacity(0.4), .clear, .black.opacity(0.2)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                        } else {
                            event.category.backgroundColor
                                .frame(height: 260 + safeTop)
                        }

                        // Category badge on image
                        Text(lang.t(event.category.labelKey))
                            .font(AppFont.theSans(size: 14, weight: .semiBold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(event.category.accentColor)
                            .cornerRadius(AppDesign.cornerRadius)
                            .padding(AppDesign.horizontalPadding)
                            .padding(.bottom, 8)
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text(lang.t(event.titleKey))
                            .font(AppFont.theMix(size: 26, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)

                        // Date and location info
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image("calendar")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(AppColors.groen3)
                                Text(event.time)
                                    .font(AppFont.bodyRegular())
                                    .foregroundColor(AppColors.textPrimary)
                            }

                            HStack(spacing: 12) {
                                Image("location-pin")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(AppColors.groen3)
                                Text(event.location)
                                    .font(AppFont.bodyRegular())
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.warmGrijs)
                        .cornerRadius(AppDesign.cornerRadius)

                        // Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text(lang.t("about_event"))
                                .font(AppFont.headingMedium())
                                .foregroundColor(AppColors.textPrimary)

                            Text(lang.t(event.descriptionKey))
                                .font(AppFont.bodyRegular())
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(4)

                            Text(extendedDescription)
                                .font(AppFont.bodyRegular())
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(4)
                        }

                        // Practical info section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(lang.t("practical_info"))
                                .font(AppFont.headingMedium())
                                .foregroundColor(AppColors.textPrimary)

                            ForEach(practicalInfo, id: \.self) { info in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(AppColors.groen3)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 8)
                                    Text(info)
                                        .font(AppFont.bodyRegular())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }

                        // CTA button
                        Button {
                            // Primary action
                        } label: {
                            HStack(spacing: 8) {
                                Text(ctaButtonText)
                                    .font(AppFont.theSans(size: 18, weight: .semiBold))
                                Image("arrow-right")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.groen3)
                            .cornerRadius(AppDesign.cornerRadius)
                        }

                        // Share button
                        Button {
                            // Share
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                Text(lang.t("share"))
                                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                            }
                            .foregroundColor(AppColors.blauw3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                                    .stroke(AppColors.blauw3, lineWidth: 1)
                            )
                        }

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, AppDesign.horizontalPadding)
                    .padding(.top, 24)
                }
            }
            .ignoresSafeArea(edges: .top)

            // Back button
            HStack {
                Button {
                    isPresented = false
                } label: {
                    Image("arrow-left")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.top, safeTop + 8)
        }
    }

    // MARK: - Content per category

    private var extendedDescription: String {
        switch event.category {
        case .community:
            if event.titleKey.contains("beach") {
                return lang.t("event_beach_long")
            } else {
                return lang.t("event_garden_long")
            }
        case .participatie:
            return lang.t("event_playground_long")
        case .melding:
            return lang.t("event_roadworks_long")
        case .cultuur:
            return lang.t("event_binnenhof_long")
        }
    }

    private var practicalInfo: [String] {
        switch event.category {
        case .community:
            if event.titleKey.contains("beach") {
                return [
                    lang.t("free_access_register"),
                    lang.t("materials_provided"),
                    lang.t("reachable_tram"),
                    lang.t("parking_garage"),
                ]
            } else {
                return [
                    lang.t("free_participation"),
                    lang.t("max_30"),
                    lang.t("sturdy_shoes"),
                    lang.t("coffee_tea"),
                ]
            }
        case .participatie:
            return [
                lang.t("free_access_no_register"),
                lang.t("sign_language"),
                lang.t("wheelchair"),
                lang.t("childcare"),
            ]
        case .melding:
            return [
                lang.t("detour_via"),
                lang.t("cyclists_follow"),
                lang.t("bus_adjusted"),
                lang.t("questions_call"),
            ]
        case .cultuur:
            return [
                lang.t("register_required"),
                lang.t("max_25"),
                lang.t("duration_90"),
                lang.t("free_residents"),
            ]
        }
    }

    private var ctaButtonText: String {
        switch event.category {
        case .community:   return lang.t("register_volunteer")
        case .participatie: return lang.t("i_participate")
        case .melding:     return lang.t("view_detour_map")
        case .cultuur:     return lang.t("register_tour")
        }
    }
}
