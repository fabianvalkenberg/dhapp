import SwiftUI

struct ChecklistItem: Identifiable {
    let id = UUID()
    let textKey: String
    var isChecked: Bool = false
}

/// Detailscherm van de afspraak (geopend via de home-statuskaart "Bekijk afspraak").
/// Zelfde clean template als de andere detail-overlays: witte achtergrond, back-knop
/// met titel ernaast, en losse elementen zonder overbodige kaders.
struct AppointmentDetailView: View {
    @EnvironmentObject var lang: LanguageManager
    var onClose: () -> Void = {}

    @State private var floatingEmoji: String? = nil
    @State private var emojiOffset: CGFloat = 0
    @State private var emojiOpacity: Double = 1
    @State private var emojiItemIndex: Int? = nil

    private let celebrationIcons = [
        "hand.thumbsup.fill", "hands.clap.fill", "hand.raised.fill", "star.fill",
        "heart.fill", "sparkles", "checkmark.seal.fill", "bolt.fill"
    ]

    @State private var checklist: [ChecklistItem] = [
        ChecklistItem(textKey: "current_passport"),
        ChecklistItem(textKey: "recent_photo"),
        ChecklistItem(textKey: "loss_report"),
        ChecklistItem(textKey: "consent_form"),
        ChecklistItem(textKey: "payment_method"),
    ]

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // Ruimte voor de zwevende back-knop; titel staat eronder (zelfde
                    // template als de paspoort- en aanvraag-pagina).
                    Color.clear.frame(height: safeTop + 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.t("your_appointment"))
                            .font(AppFont.theMix(size: 30, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text(lang.t("passport_request"))
                            .font(AppFont.theSans(size: 16, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Datum / tijd / locatie — netjes in één boxje
                    VStack(spacing: 0) {
                        plainInfoRow(icon: "calendar", label: lang.t("date"), value: lang.t("appointment_date"))
                            .padding(16)
                        Rectangle().fill(AppColors.grijs2).frame(height: 1)
                        plainInfoRow(icon: "clock", label: lang.t("time"), value: lang.t("appointment_time"), useSFSymbol: true)
                            .padding(16)
                        Rectangle().fill(AppColors.grijs2).frame(height: 1)
                        plainInfoRow(icon: "location-pin", label: lang.t("location"), value: lang.t("appointment_location"))
                            .padding(16)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.grijs2, lineWidth: 1))

                    // Meenemen-checklist — het belangrijkste, dus een slag groter en
                    // zonder lijntjes tussen de items.
                    VStack(alignment: .leading, spacing: 16) {
                        Text(lang.t("make_sure_ready"))
                            .font(AppFont.theSans(size: 17, weight: .plain))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)

                        VStack(spacing: 4) {
                            ForEach(Array(checklist.enumerated()), id: \.element.id) { index, item in
                                checklistRow(index: index, item: item)
                            }
                        }
                    }

                    // Kosten — nette borderloze tabel
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lang.t("costs"))
                            .font(AppFont.theMix(size: 22, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)

                        VStack(spacing: 0) {
                            costRow(label: lang.t("passport_adult"), value: lang.t("passport_price"))
                            Rectangle().fill(AppColors.grijs2).frame(height: 1)
                            costRow(label: lang.t("express_rate"), value: lang.t("express_price"))
                        }
                    }

                    // Goed om te weten (blijft zoals het was — werkt goed)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lang.t("good_to_know"))
                            .font(AppFont.theMix(size: 22, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)

                        VStack(alignment: .leading, spacing: 12) {
                            tipRow(text: lang.t("tip_on_time"))
                            tipRow(text: lang.t("tip_validity"))
                            tipRow(text: lang.t("tip_pickup"))
                            tipRow(text: lang.t("tip_bring_old"))
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.warmGrijs)
                        .cornerRadius(8)
                    }

                    // Acties
                    VStack(spacing: 12) {
                        actionButton(title: lang.t("reschedule"), filled: true)
                        actionButton(title: lang.t("cancel_appointment"), filled: false)
                    }

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }

            // Zwevende back-knop (titel scrollt eronder weg) — zelfde patroon overal.
            BackCircleButton { onClose() }
                .padding(.leading, AppDesign.horizontalPadding)
                .padding(.top, safeTop + 6)
        }
    }

    // MARK: - Checklist-rij (groter)

    private func checklistRow(index: Int, item: ChecklistItem) -> some View {
        ZStack(alignment: .leading) {
            Button {
                let wasChecked = checklist[index].isChecked
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    checklist[index].isChecked.toggle()
                }
                if !wasChecked { triggerEmoji(at: index) }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .stroke(item.isChecked ? AppColors.groen3 : AppColors.grijs2, lineWidth: 1.5)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(item.isChecked ? AppColors.groen3 : Color.clear))
                        if item.isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .scaleEffect(item.isChecked ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: item.isChecked)

                    Text(lang.t(item.textKey))
                        .font(AppFont.theSans(size: 18, weight: .semiBold))
                        .foregroundColor(item.isChecked ? AppColors.textSecondary : AppColors.textPrimary)
                        .strikethrough(item.isChecked, color: AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if emojiItemIndex == index, let icon = floatingEmoji {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppColors.groen3)
                    .offset(x: 0, y: emojiOffset)
                    .opacity(emojiOpacity)
                    .allowsHitTesting(false)
            }
        }
    }

    private func actionButton(title: String, filled: Bool) -> some View {
        Button {} label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                Spacer()
                Image("arrow-right")
                    .renderingMode(.template).resizable().scaledToFit()
                    .frame(width: 16, height: 16)
            }
            .foregroundColor(filled ? .white : AppColors.rood)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(filled ? AppColors.groen3 : Color.white)
            .cornerRadius(AppDesign.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                    .stroke(filled ? Color.clear : AppColors.rood.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Emoji-celebratie

    private func triggerEmoji(at index: Int) {
        let icon = celebrationIcons.randomElement() ?? "hand.thumbsup.fill"
        floatingEmoji = icon
        emojiItemIndex = index
        emojiOffset = 0
        emojiOpacity = 1
        withAnimation(.easeOut(duration: 0.8)) {
            emojiOffset = -50
            emojiOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            floatingEmoji = nil
            emojiItemIndex = nil
        }
    }

    // MARK: - Losse rijen

    private func plainInfoRow(icon: String, label: String, value: String, useSFSymbol: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Group {
                if useSFSymbol {
                    Image(systemName: icon).font(.system(size: 17))
                } else {
                    Image(icon).renderingMode(.template).resizable().scaledToFit().frame(width: 20, height: 20)
                }
            }
            .foregroundColor(AppColors.groen3)
            .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFont.theSans(size: 14, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                Text(value)
                    .font(AppFont.theSans(size: 17, weight: .semiBold))
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
        }
    }

    private func costRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppFont.theSans(size: 16, weight: .semiBold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.vertical, 14)
    }

    private func tipRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(AppColors.groen3)
                .frame(width: 6, height: 6)
                .padding(.top, 8)
            Text(text)
                .font(AppFont.theSans(size: 16, weight: .plain))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
        }
    }
}
