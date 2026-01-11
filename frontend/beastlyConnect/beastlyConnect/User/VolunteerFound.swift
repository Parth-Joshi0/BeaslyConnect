//
//  VolunteerFound.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-11.
//
import SwiftUI
import MapKit

struct VolunteerFound: View {
    var body: some View {
        ScrollView {
            TopHeader(titleText: "Help is on the way! 🎉", secondaryText: "Your volunteer is coming")
            
            Divider()
            
            VolunteerRouteCard(
                userCoordinate: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
                volunteerCoordinate: CLLocationCoordinate2D(latitude: 43.7000, longitude: -79.4000)
            )
            
            VolunteerInfoCard(
                volunteer: Volunteer(
                    id: "vol_1",
                    name: "Sarah Johnson",
                    bio: "Experienced volunteer with a passion for helping the community",
                    imageURL: URL(string: "https://example.com/sarah.jpg"),
                    phoneNumber: "2897072625"
                ),
                onCall: { v in
                        if let phone = v.phoneNumber {
                            callVolunteer(phone)
                        }
                    },
                    onMessage: { v in
                        if let phone = v.phoneNumber {
                            messageVolunteer(phone)
                        }
                    }
            )

        }
    }
}

struct VolunteerRouteCard: View {
    // Input coordinates (from backend / location services)
    var userCoordinate: CLLocationCoordinate2D
    var volunteerCoordinate: CLLocationCoordinate2D

    // Optional overrides (if your backend provides these)
    var etaTextOverride: String? = nil
    var distanceTextOverride: String? = nil

    @State private var route: MKRoute? = nil
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $camera) {
                // Route polyline
                if let polyline = route?.polyline {
                    MapPolyline(polyline)
                        .stroke(.purple.opacity(0.8), lineWidth: 6)
                }

                // Annotations
                Annotation("You", coordinate: userCoordinate) {
                    MapPinBubble(
                        title: "You",
                        icon: "mappin.and.ellipse",
                        circleColor: .orange
                    )
                }

                Annotation("Volunteer", coordinate: volunteerCoordinate) {
                    MapPinBubble(
                        title: "Volunteer",
                        icon: "car.fill",
                        circleColor: .purple
                    )
                }
            }
            .mapStyle(.standard)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(Color.blue.opacity(0.18), lineWidth: 1.5)
            )
            .onAppear {
                fitCamera()
                Task { await computeRoute() }
            }
            .onChange(of: userCoordinate.latitude) { _ in
                fitCamera()
                Task { await computeRoute() }
            }
            .onChange(of: volunteerCoordinate.latitude) { _ in
                fitCamera()
                Task { await computeRoute() }
            }

            bottomInfoBar
        }
        .frame(height: 360)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.10), radius: 18, y: 10)
    }

    // MARK: - Bottom Bar
    private var bottomInfoBar: some View {
        HStack(spacing: 18) {
            // Left: clock icon
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 56, height: 56)

                Image(systemName: "clock")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Estimated Arrival")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))

                Text(etaText)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Distance")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))

                Text(distanceText)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: [Color.purple, Color.pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
        )
    }

    private var etaText: String {
        if let etaTextOverride { return etaTextOverride }
        guard let seconds = route?.expectedTravelTime else { return "--" }
        let minutes = Int((seconds / 60.0).rounded())
        return "\(minutes) minutes"
    }

    private var distanceText: String {
        if let distanceTextOverride { return distanceTextOverride }
        guard let meters = route?.distance else { return "--" }
        let km = meters / 1000.0
        if km < 1 {
            let m = Int(meters.rounded())
            return "\(m) m away"
        } else {
            return String(format: "%.1f km away", km)
        }
    }

    private func fitCamera() {
        let latMin = min(userCoordinate.latitude, volunteerCoordinate.latitude)
        let latMax = max(userCoordinate.latitude, volunteerCoordinate.latitude)
        let lonMin = min(userCoordinate.longitude, volunteerCoordinate.longitude)
        let lonMax = max(userCoordinate.longitude, volunteerCoordinate.longitude)

        let center = CLLocationCoordinate2D(
            latitude: (latMin + latMax) / 2,
            longitude: (lonMin + lonMax) / 2
        )

        // Padding so pins aren’t on the edges
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (latMax - latMin) * 1.8),
            longitudeDelta: max(0.01, (lonMax - lonMin) * 1.8)
        )

        camera = .region(MKCoordinateRegion(center: center, span: span))
    }

    private func computeRoute() async {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: volunteerCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: userCoordinate))
        request.transportType = .automobile // change to .walking if you want

        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            route = response.routes.first
        } catch {
            // If routing fails (no network / etc.), just show pins
            route = nil
        }
    }
}

struct MapPinBubble: View {
    var title: String
    var icon: String
    var circleColor: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 54, height: 54)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.9), lineWidth: 6)
            )
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
        }
    }
}

struct Volunteer: Identifiable {
    let id: String
    let name: String
    let bio: String
    let imageURL: URL?

    // Optional contact info
    let phoneNumber: String?
}

struct VolunteerInfoCard: View {
    var title: String = "Your Volunteer"
    var volunteer: Volunteer

    // Actions (you decide behavior)
    var onCall: ((Volunteer) -> Void)? = nil
    var onMessage: ((Volunteer) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)

            HStack(alignment: .top, spacing: 16) {
                avatar

                VStack(alignment: .leading, spacing: 10) {
                    Text(volunteer.name)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(volunteer.bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 14) {
                ActionGradientButton(
                    title: "Call",
                    systemImage: "phone.fill",
                    colors: [Color.green, Color.teal],
                    isEnabled: volunteer.phoneNumber != nil,
                    action: { onCall?(volunteer) }
                )

                ActionGradientButton(
                    title: "Message",
                    systemImage: "bubble.left.and.bubble.right.fill",
                    colors: [Color.blue, Color.cyan],
                    action: { onMessage?(volunteer) }
                )
            }
            .padding(.top, 6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.blue.opacity(0.20), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
        .padding(.horizontal)
    }

    // MARK: - Avatar
    private var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.purple.opacity(0.12))
                .frame(width: 86, height: 86)

            if let url = volunteer.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        fallbackAvatar
                    default:
                        ProgressView()
                    }
                }
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                fallbackAvatar
            }
        }
    }

    private var fallbackAvatar: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(.purple.opacity(0.8))
            .frame(width: 76, height: 76)
            .background(Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct ActionGradientButton: View {
    var title: String
    var systemImage: String
    var colors: [Color]
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button {
            if isEnabled { action() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(isEnabled ? 1.0 : 0.55)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

func callVolunteer(_ phoneNumber: String) {
    let cleaned = phoneNumber
        .components(separatedBy: CharacterSet.decimalDigits.inverted)
        .joined()

    guard let url = URL(string: "tel://\(cleaned)"),
          UIApplication.shared.canOpenURL(url) else { return }

    UIApplication.shared.open(url)
}

func messageVolunteer(_ phoneNumber: String) {
    let cleaned = phoneNumber
        .components(separatedBy: CharacterSet.decimalDigits.inverted)
        .joined()

    guard let url = URL(string: "sms:\(cleaned)"),
          UIApplication.shared.canOpenURL(url) else { return }

    UIApplication.shared.open(url)
}
