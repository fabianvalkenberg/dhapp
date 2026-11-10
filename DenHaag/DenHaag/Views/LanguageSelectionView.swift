import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var lang: LanguageManager
    @Binding var isPresented: Bool

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: safeTop + 56)

                // Title
                Text(lang.t("language"))
                    .font(AppFont.theMix(size: 26, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppDesign.horizontalPadding)
                    .padding(.bottom, 24)

                // Language options
                VStack(spacing: 0) {
                    ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, language in
                        Button {
                            lang.current = language
                        } label: {
                            HStack(spacing: 16) {
                                Text(language.flag)
                                    .font(.system(size: 28))

                                Text(language.displayName)
                                    .font(AppFont.theSans(size: 18, weight: lang.current == language ? .bold : .plain))
                                    .foregroundColor(AppColors.textPrimary)

                                Spacer()

                                if lang.current == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(AppColors.groen3)
                                } else {
                                    Circle()
                                        .stroke(AppColors.grijs2, lineWidth: 1.5)
                                        .frame(width: 22, height: 22)
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                        }
                        .buttonStyle(.plain)

                        if index < AppLanguage.allCases.count - 1 {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.grijs2, lineWidth: 1)
                )
                .padding(.horizontal, AppDesign.horizontalPadding)

                Spacer()
            }

            // Back button
            HStack {
                BackCircleButton(stijl: .wit) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPresented = false
                    }
                }
                Spacer()
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.top, safeTop + 8)
        }
    }
}
