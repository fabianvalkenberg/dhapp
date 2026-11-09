import SwiftUI

// MARK: - Process Step Model

private struct ProcessStep: Identifiable {
    let id = UUID()
    let titleKey: String
    let descriptionKey: String?
    let dateKey: String?
    let status: StepStatus

    enum StepStatus {
        case completed
        case current
        case upcoming
    }
}

// MARK: - Kwijtschelding Detail View

struct KwijtscheldingDetailView: View {
    @EnvironmentObject var lang: LanguageManager
    @Binding var isPresented: Bool

    /// De uitlegvideo die nu schermvullend speelt (nil = geen).
    @State private var actieveVideo: ExplainerVideo?

    private let steps: [ProcessStep] = [
        ProcessStep(
            titleKey: "kw_step_submitted",
            descriptionKey: "kw_step_submitted_desc",
            dateKey: "kw_date_submitted",
            status: .completed
        ),
        ProcessStep(
            titleKey: "kw_step_received",
            descriptionKey: "kw_step_received_desc",
            dateKey: "kw_date_received",
            status: .completed
        ),
        ProcessStep(
            titleKey: "kw_step_review",
            descriptionKey: "kw_step_review_desc",
            dateKey: nil,
            status: .current
        ),
        ProcessStep(
            titleKey: "kw_step_decision",
            descriptionKey: nil,
            dateKey: nil,
            status: .upcoming
        ),
    ]

    private var safeTop: CGFloat { AppDesign.safeAreaTop }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    ZStack(alignment: .bottomLeading) {
                        AppColors.groen3
                            .frame(height: safeTop + 140)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(lang.t("kw_title"))
                                .font(AppFont.theMix(size: 26, weight: .bold))
                                .foregroundColor(.white)

                            Text(lang.t("kw_subtitle_header"))
                                .font(AppFont.theSans(size: 18, weight: .plain))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.horizontal, AppDesign.horizontalPadding)
                        .padding(.bottom, 24)
                    }

                    VStack(alignment: .leading, spacing: AppDesign.sectionSpacing) {
                        // Status badge
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: "E8890C"))
                                .frame(width: 8, height: 8)
                            Text(lang.t("kw_status_processing"))
                                .font(AppFont.theSans(size: 14, weight: .semiBold))
                                .foregroundColor(Color(hex: "E8890C"))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: "E8890C").opacity(0.1))
                        .cornerRadius(20)
                        .padding(.top, 24)

                        // Verwachte afhandeling
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lang.t("kw_expected_date_label"))
                                .font(AppFont.theSans(size: 14, weight: .plain))
                                .foregroundColor(AppColors.textSecondary)
                            Text(lang.t("kw_expected_date"))
                                .font(AppFont.theMix(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                        }

                        // Uitleg in korte video's — staat vóór de tijdlijn,
                        // zodat je eerst kunt snappen wát je hebt aangevraagd.
                        ExplainerCardView(reeks: VideoLibrary.kwijtschelding) { video in
                            actieveVideo = video
                        }

                        // Process timeline
                        VStack(alignment: .leading, spacing: 0) {
                            Text(lang.t("kw_process_title"))
                                .font(AppFont.theMix(size: 22, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.bottom, 20)

                            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                                stepRow(step: step, isLast: index == steps.count - 1)
                            }
                        }

                        // Info block
                        VStack(alignment: .leading, spacing: 12) {
                            Text(lang.t("kw_info_title"))
                                .font(AppFont.theMix(size: 22, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            VStack(alignment: .leading, spacing: 12) {
                                infoRow(text: lang.t("kw_info_1"))
                                infoRow(text: lang.t("kw_info_2"))
                                infoRow(text: lang.t("kw_info_3"))
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.warmGrijs)
                            .cornerRadius(8)
                        }

                        // Contact button
                        Button {} label: {
                            HStack(spacing: 6) {
                                Text(lang.t("kw_contact"))
                                    .font(AppFont.theSans(size: 16, weight: .semiBold))
                                Spacer()
                                Image("arrow-right")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.groen3)
                            .cornerRadius(AppDesign.cornerRadius)
                        }

                        Spacer().frame(height: 60)
                    }
                    .padding(.horizontal, AppDesign.horizontalPadding)
                }
            }
            .ignoresSafeArea(edges: .top)

            // Close button
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, AppDesign.horizontalPadding)
            .padding(.top, safeTop + 8)
        }
        .fullScreenCover(item: $actieveVideo) { video in
            ExplainerPlayerView(
                reeks: VideoLibrary.kwijtschelding,
                huidige: video,
                isPresented: Binding(
                    get: { actieveVideo != nil },
                    set: { if !$0 { actieveVideo = nil } }
                )
            )
            .environmentObject(lang)
        }
    }

    // MARK: - Step Row

    @ViewBuilder
    private func stepRow(step: ProcessStep, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            VStack(spacing: 0) {
                ZStack {
                    switch step.status {
                    case .completed:
                        Circle()
                            .fill(AppColors.groen3)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    case .current:
                        Circle()
                            .fill(Color(hex: "E8890C"))
                            .frame(width: 28, height: 28)
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10)
                    case .upcoming:
                        Circle()
                            .stroke(AppColors.grijs2, lineWidth: 2)
                            .frame(width: 28, height: 28)
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(step.status == .upcoming ? AppColors.grijs2 : AppColors.groen3)
                        .frame(width: 2)
                        .frame(minHeight: 40)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(lang.t(step.titleKey))
                    .font(AppFont.theSans(size: 16, weight: step.status == .upcoming ? .plain : .semiBold))
                    .foregroundColor(step.status == .upcoming ? AppColors.textSecondary : AppColors.textPrimary)

                if let descKey = step.descriptionKey {
                    Text(lang.t(descKey))
                        .font(AppFont.theSans(size: 14, weight: .plain))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(3)
                }

                if let dateKey = step.dateKey {
                    Text(lang.t(dateKey))
                        .font(AppFont.theSans(size: 13, weight: .plain))
                        .foregroundColor(AppColors.textSecondary.opacity(0.7))
                        .padding(.top, 2)
                }
            }
            .padding(.bottom, isLast ? 0 : 16)

            Spacer()
        }
    }

    // MARK: - Info Row

    private func infoRow(text: String) -> some View {
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
