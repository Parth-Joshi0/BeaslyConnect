import SwiftUI

// MARK: - Popup Card

struct ProfilePopupCard: View {
    @Binding var isPresented: Bool

    // ✅ Use your help request directly (no backend needed)
    var helpRequest: HelpRequest

    var onDecline: (() -> Void)? = nil
    var onAccept: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    header

                    VStack(spacing: 16) {
                        Spacer().frame(height: 40)

                        Text(helpRequest.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        if let phone = helpRequest.phone, !phone.isEmpty {
                            HStack(spacing: 10) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.secondary)

                                Text(phone)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        urgencyRow

                        Divider()
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("About")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(helpRequest.aboutText)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                }
                .frame(maxWidth: 360)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 22, x: 0, y: 10)

                actionButtons
                    .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var header: some View {
        LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 130)
        .overlay(alignment: .bottom) {
            avatar
                .offset(y: 62)
        }
    }

    private var avatar: some View {
        Image(systemName: helpRequest.avatarSystemImage)
            .resizable()
            .scaledToFill()
            .frame(width: 110, height: 110)
            .foregroundStyle(Color.white.opacity(0.95))
            .background(Color.black.opacity(0.08))
            .clipShape(Circle())
            .overlay(
                Circle().stroke(Color.white, lineWidth: 5)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
    }

    private var urgencyRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.secondary)

            Text("Urgency:")
                .foregroundStyle(.secondary)

            Text(helpRequest.urgency.title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(helpRequest.urgency.pillBackground)
                .foregroundStyle(helpRequest.urgency.pillForeground)
                .clipShape(Capsule())

            Spacer()
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    onDecline?()
                }
            } label: {
                Text("Decline")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
                            )
                    )
            }

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    onAccept?()
                }
            } label: {
                Text("Accept")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.blue)
                    )
            }
        }
        .frame(maxWidth: 360)
    }
}

// MARK: - Your "Help Request" Model (local/offline)

struct HelpRequest: Identifiable, Codable {
    var id: String = UUID().uuidString

    var name: String? = "Goblin1"
    var phone: String? = "1234345576"
    var urgency: Urgency = .low
    var about: String? = "My grandma needs help with shopping"

    // ✅ renamed so it won't conflict
    var avatarSystemImageRaw: String? = "person.crop.circle.fill"
}

extension HelpRequest {
    var displayName: String {
        let n = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "Unknown" : n
    }

    var aboutText: String {
        let a = (about ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return a.isEmpty ? "No details provided." : a
    }

    // ✅ computed non-optional value used by the UI
    var avatarSystemImage: String {
        let icon = (avatarSystemImageRaw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return icon.isEmpty ? "person.crop.circle.fill" : icon
    }
}

// MARK: - Urgency

enum Urgency: String, Codable {
    case low, medium, high

    var title: String { rawValue.capitalized }

    var pillForeground: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    var pillBackground: Color {
        pillForeground.opacity(0.15)
    }
}
