import SwiftUI

// MARK: - FAQ Category

enum FAQCategory: String, Identifiable {
    case parking
    case living
    case money

    var id: String { rawValue }
}

// MARK: - FAQ Section with expandable items

struct FAQSection: Identifiable {
    let id = UUID()
    let titleKey: String
    let items: [FAQItem]
}

struct FAQItem: Identifiable {
    let id = UUID()
    let questionKey: String
    let answerKey: String
}

// MARK: - FAQ Data

struct FAQData {
    static func sections(for category: FAQCategory) -> [FAQSection] {
        switch category {
        case .parking:
            return [
                FAQSection(titleKey: "faq_parking_permits", items: [
                    FAQItem(questionKey: "faq_parking_q1", answerKey: "faq_parking_a1"),
                    FAQItem(questionKey: "faq_parking_q2", answerKey: "faq_parking_a2"),
                    FAQItem(questionKey: "faq_parking_q3", answerKey: "faq_parking_a3"),
                    FAQItem(questionKey: "faq_parking_q4", answerKey: "faq_parking_a4"),
                ]),
                FAQSection(titleKey: "faq_parking_paying", items: [
                    FAQItem(questionKey: "faq_parking_pay_q1", answerKey: "faq_parking_pay_a1"),
                    FAQItem(questionKey: "faq_parking_pay_q2", answerKey: "faq_parking_pay_a2"),
                ]),
            ]
        case .living:
            return [
                FAQSection(titleKey: "faq_living_moving", items: [
                    FAQItem(questionKey: "faq_living_q1", answerKey: "faq_living_a1"),
                    FAQItem(questionKey: "faq_living_q2", answerKey: "faq_living_a2"),
                    FAQItem(questionKey: "faq_living_q3", answerKey: "faq_living_a3"),
                ]),
                FAQSection(titleKey: "faq_living_permits", items: [
                    FAQItem(questionKey: "faq_living_q4", answerKey: "faq_living_a4"),
                    FAQItem(questionKey: "faq_living_q5", answerKey: "faq_living_a5"),
                ]),
            ]
        case .money:
            return [
                FAQSection(titleKey: "faq_money_taxes", items: [
                    FAQItem(questionKey: "faq_money_q1", answerKey: "faq_money_a1"),
                    FAQItem(questionKey: "faq_money_q2", answerKey: "faq_money_a2"),
                    FAQItem(questionKey: "faq_money_q3", answerKey: "faq_money_a3"),
                ]),
                FAQSection(titleKey: "faq_money_support", items: [
                    FAQItem(questionKey: "faq_money_q4", answerKey: "faq_money_a4"),
                    FAQItem(questionKey: "faq_money_q5", answerKey: "faq_money_a5"),
                ]),
            ]
        }
    }
}

// MARK: - FAQ Detail View

struct HelpFAQView: View {
    @EnvironmentObject var lang: LanguageManager
    let category: FAQCategory
    @Binding var isPresented: FAQCategory?

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button {
                    isPresented = nil
                } label: {
                    Image("arrow-left")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(hex: "2D2D2D"))
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(22)
                }
                Spacer()
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Category title
                    Text(lang.t(categoryTitleKey))
                        .font(AppFont.theMix(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "2D2D2D"))

                    // FAQ sections
                    ForEach(FAQData.sections(for: category)) { section in
                        FAQSectionView(section: section)
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private var categoryTitleKey: String {
        switch category {
        case .parking: return "faq_title_parking"
        case .living: return "faq_title_living"
        case .money: return "faq_title_money"
        }
    }
}

// MARK: - FAQ Section View

struct FAQSectionView: View {
    @EnvironmentObject var lang: LanguageManager
    let section: FAQSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section heading
            Text(lang.t(section.titleKey))
                .font(AppFont.headingLarge())
                .foregroundColor(Color(hex: "2D2D2D"))

            // Accordion items
            VStack(spacing: 0) {
                ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                    AccordionItem(item: item, isLast: index == section.items.count - 1)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(hex: "7A7A7A"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }
}

// MARK: - Accordion Item

struct AccordionItem: View {
    @EnvironmentObject var lang: LanguageManager
    let item: FAQItem
    let isLast: Bool
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Question button — entire row is tappable
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Text(lang.t(item.questionKey))
                        .font(AppFont.theSans(size: 16, weight: .semiBold))
                        .foregroundColor(Color(hex: "2D2D2D"))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "2D2D2D"))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Answer (expandable with smooth animation)
            if isExpanded {
                Text(lang.t(item.answerKey))
                    .font(AppFont.theSans(size: 15, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                        removal: .opacity
                    ))
            }

            // Divider
            if !isLast || isExpanded {
                Rectangle()
                    .fill(AppColors.grijs2)
                    .frame(height: 1)
            }
        }
        .background(isExpanded ? AppColors.warmGrijs.opacity(0.3) : Color.white)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}
