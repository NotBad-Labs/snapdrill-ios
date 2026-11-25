import SwiftUI

/// Calm transient status banners (5-second undo delete, post-save toast, interrupted-draft recovery).
/// Attach with `.safeAreaInset(edge: .bottom)` so the system keeps them clear of the tab bar / bottom toolbar.
struct TransientStatusBanners: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(spacing: 8) {
            if environment.undoBannerCount > 0 {
                undoDeleteBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let savedCount = environment.savedToastQuestionCount {
                savedToastBanner(count: savedCount)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let draft = environment.recoverableDraft {
                draftRecoveryBanner(draft: draft)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, hasVisibleBanner ? 8 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: environment.undoBannerCount)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: environment.savedToastQuestionCount)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: environment.recoverableDraft?.id)
        .sensoryFeedback(.success, trigger: environment.savedToastQuestionCount) { _, new in new != nil }
        .sensoryFeedback(.warning, trigger: environment.undoBannerCount) { old, new in new > old }
    }

    private var hasVisibleBanner: Bool {
        environment.undoBannerCount > 0
            || environment.savedToastQuestionCount != nil
            || environment.recoverableDraft != nil
    }

    private var undoDeleteBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .foregroundStyle(.white.opacity(0.85))
            Text("Deleted (\(environment.undoBannerCount))")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Button("Undo") {
                environment.undoLastDeletion()
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(SnapDrillTheme.pencilYellow)
            .frame(minHeight: 44)
            .accessibilityLabel(String(localized: "Undo Delete"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Color(hexString: "1F1F22"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func savedToastBanner(count: Int) -> some View {
        HStack(spacing: 10) {
            PandaMascotView(mood: .savedBadge, size: 30)
            Text("Saved \(count) — ready when you want to practice")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SnapDrillTheme.inkBlack)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(SnapDrillTheme.cardSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 16)
    }

    private func draftRecoveryBanner(draft: CaptureSession) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.badge.clock")
                .foregroundStyle(SnapDrillTheme.inkBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Resume unfinished capture?")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlack)
                Text("\(draft.pages.count) pages · \(draft.totalBoxCount) questions")
                    .font(.caption2)
                    .foregroundStyle(SnapDrillTheme.inkSecondary)
            }
            Spacer()
            Button("Discard") {
                Task { await environment.discardRecoverableDraft() }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(SnapDrillTheme.inkSecondary)
            .frame(minHeight: 44)

            Button("Resume") {
                environment.requestCapture(resumeSession: draft)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(SnapDrillTheme.inkBlue, in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(SnapDrillTheme.cardSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(SnapDrillTheme.inkBlue.opacity(0.35), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 16)
    }
}
