import SwiftUI

struct CustomizeHomeView: View {
    @EnvironmentObject var lang: LanguageManager
    @ObservedObject var settings: HomeSettingsModel
    @Binding var isPresented: Bool

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Back button
                Button {
                    isPresented = false
                } label: {
                    Image("arrow-left")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(AppColors.blauw3)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .padding(.horizontal, AppDesign.horizontalPadding)
                .padding(.top, safeTop + 8)

                // Title
                Text(lang.t("customize_home"))
                    .font(AppFont.headingLarge())
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, AppDesign.horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                // Toggle list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(settings.tiles) { tile in
                            VStack(spacing: 0) {
                                HStack {
                                    Text(lang.t(tile.titleKey))
                                        .font(AppFont.bodyRegular())
                                        .foregroundColor(AppColors.textPrimary)

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: { tile.isSelected },
                                        set: { _ in
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                settings.toggleTile(id: tile.id)
                                            }
                                        }
                                    ))
                                    .tint(AppColors.groen3)
                                    .labelsHidden()
                                }
                                .padding(.horizontal, AppDesign.horizontalPadding)
                                .padding(.vertical, 18)

                                Divider()
                                    .padding(.horizontal, AppDesign.horizontalPadding)
                            }
                        }
                    }
                }
            }
        }
    }
}
