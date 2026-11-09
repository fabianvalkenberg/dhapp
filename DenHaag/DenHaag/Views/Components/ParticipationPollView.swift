import SwiftUI

struct ParticipationPollView: View {
    @EnvironmentObject var lang: LanguageManager
    @State private var selectedOption: Int? = nil
    @State private var hasVoted = false
    @State private var wantsUpdates = false
    @State private var showKeepUpdated = false

    // Simulated vote counts (would come from API in production)
    @State private var votes = [38, 27, 15]

    private var totalVotes: Int { votes.reduce(0, +) }

    private let options = [
        "poll_option_1",
        "poll_option_2",
        "poll_option_3"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Text(lang.t("participation"))
                    .font(AppFont.theMix(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text(lang.t("poll_votes_count").replacingOccurrences(of: "{count}", with: "\(totalVotes)"))
                    .font(AppFont.theSans(size: 13, weight: .plain))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, AppDesign.horizontalPadding)

            // Question card
            VStack(alignment: .leading, spacing: 16) {
                Text(lang.t("poll_question"))
                    .font(AppFont.theSans(size: 17, weight: .semiBold))
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // Options
                VStack(spacing: 10) {
                    ForEach(0..<options.count, id: \.self) { index in
                        PollOptionRow(
                            text: lang.t(options[index]),
                            voteCount: votes[index],
                            totalVotes: totalVotes,
                            isSelected: selectedOption == index,
                            hasVoted: hasVoted,
                            onTap: {
                                guard !hasVoted else { return }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedOption = index
                                }
                            }
                        )
                    }
                }

                // Vote button
                if !hasVoted {
                    Button {
                        guard let selected = selectedOption else { return }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            votes[selected] += 1
                            hasVoted = true
                        }
                    } label: {
                        HStack {
                            Text(lang.t("poll_vote"))
                                .font(AppFont.theSans(size: 16, weight: .semiBold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedOption != nil ? AppColors.groen3 : AppColors.grijs2)
                        .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                    }
                    .disabled(selectedOption == nil)
                } else {
                    // Thank you message
                    VStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.groen3)
                            Text(lang.t("poll_thanks"))
                                .font(AppFont.theSans(size: 14, weight: .semiBold))
                                .foregroundColor(AppColors.groen3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "E8F5E9"))
                        .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))

                        // Keep me updated button
                        if showKeepUpdated {
                            if wantsUpdates {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.blauw3)
                                    Text(lang.t("poll_updates_confirmed"))
                                        .font(AppFont.theSans(size: 14, weight: .semiBold))
                                        .foregroundColor(AppColors.blauw3)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppColors.blauw3.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: AppDesign.cornerRadius))
                                .transition(.scale.combined(with: .opacity))
                            } else {
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        wantsUpdates = true
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bell")
                                            .font(.system(size: 14))
                                        Text(lang.t("poll_keep_updated"))
                                            .font(AppFont.theSans(size: 14, weight: .semiBold))
                                    }
                                    .foregroundColor(AppColors.blauw3)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                                            .stroke(AppColors.blauw3.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6)) {
                            showKeepUpdated = true
                        }
                    }
                }
            }
            .padding(16)
            .background(AppColors.backgroundGrey)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, AppDesign.horizontalPadding)
        }
    }
}

// MARK: - Poll Option Row

struct PollOptionRow: View {
    let text: String
    let voteCount: Int
    let totalVotes: Int
    let isSelected: Bool
    let hasVoted: Bool
    let onTap: () -> Void

    private var percentage: CGFloat {
        totalVotes > 0 ? CGFloat(voteCount) / CGFloat(totalVotes) : 0
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .leading) {
                // Background bar (shown after voting)
                if hasVoted {
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                            .fill(isSelected ? AppColors.blauw3.opacity(0.15) : Color.gray.opacity(0.08))
                            .frame(width: geo.size.width * percentage)
                    }
                }

                HStack(spacing: 12) {
                    // Radio circle
                    ZStack {
                        Circle()
                            .stroke(isSelected ? AppColors.blauw3 : AppColors.grijs2, lineWidth: 2)
                            .frame(width: 22, height: 22)

                        if isSelected {
                            Circle()
                                .fill(AppColors.blauw3)
                                .frame(width: 12, height: 12)
                        }
                    }

                    Text(text)
                        .font(AppFont.theSans(size: 15, weight: isSelected ? .semiBold : .plain))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    if hasVoted {
                        Text("\(Int(percentage * 100))%")
                            .font(AppFont.theSans(size: 14, weight: .semiBold))
                            .foregroundColor(isSelected ? AppColors.blauw3 : AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                    .stroke(isSelected ? AppColors.blauw3 : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
