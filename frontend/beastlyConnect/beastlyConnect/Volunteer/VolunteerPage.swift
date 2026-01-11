//
//  VolunteerPage.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-10.
//

import CoreLocation
import MapKit
import SwiftUI
import Foundation
import Combine

struct VolunteerView: View {
    @EnvironmentObject var auth: AuthState
    
    @State private var totalHours: Int = 24
    @State private var totalConnections: Int = 8
    @State private var hasProfile: Bool = false
    @State private var lookingForUsers: Bool = false
    @State private var isLoadingProfile: Bool = true
    @State private var errorMessage: String?
    @State private var pendingRequests: [PendingHelpRequest] = []
    @State private var currentRequestIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoadingProfile {
                    ProgressView("Checking profile...")
                        .scaleEffect(1.2)
                } else {
                    ScrollView {
                        VStack {
                            TopHeader(titleText: "Volunteer Dashboard", secondaryText: "Welcome back!")

                            Divider()

                            Spacer(minLength: 24)

                            HStack(spacing: 14) {
                                StatsCard(
                                    icon: "clock",
                                    iconBg: Color.blue.opacity(0.12),
                                    iconFg: Color.blue,
                                    value: "\(totalHours)",
                                    label: "Hours",
                                    plusColor: Color.blue
                                )

                                StatsCard(
                                    icon: "person.2",
                                    iconBg: Color.green.opacity(0.12),
                                    iconFg: Color.green,
                                    value: "\(totalConnections)",
                                    label: "Connections",
                                    plusColor: Color.green
                                )
                            }

                            Spacer(minLength: 24)

                            Text("Quick Actions").font(
                                .system(size: 22, weight: .semibold)
                            )
                            .foregroundStyle(.gray)
                            .padding(.top, 6)

                            Spacer(minLength: 24)

                            VStack(spacing: 12) {
                                if hasProfile {
                                    NavigationLink {
                                        VolunteerProfile(mode: .update) {
                                            hasProfile = true
                                        }
                                        .navigationBarBackButtonHidden(true)
                                    } label: {
                                        RowCard(
                                            icon: "person.crop.circle",
                                            iconBg: Color.purple.opacity(0.12),
                                            iconFg: Color.purple,
                                            title: "Update Profile",
                                            subtitle: "Edit your information"
                                        )
                                    }

                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Connect with users")
                                                .font(
                                                    .system(
                                                        size: 17,
                                                        weight: .semibold
                                                    )
                                                )

                                            Text(
                                                "Show nearby requests in real time"
                                            )
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        ToggleButton(isOn: $lookingForUsers)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(
                                            cornerRadius: 18,
                                            style: .continuous
                                        )
                                        .fill(
                                            Color(.secondarySystemGroupedBackground)
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(
                                            cornerRadius: 18,
                                            style: .continuous
                                        )
                                        .stroke(
                                            Color.black.opacity(0.06),
                                            lineWidth: 1
                                        )
                                    )
                                    .contentShape(Rectangle())
                                    .onChange(of: lookingForUsers) { _, newValue in
                                        if newValue {
                                            Task {
                                                await fetchPendingRequests()
                                            }
                                        }
                                    }

                                } else {
                                    NavigationLink {
                                        VolunteerProfile(mode: .create) {
                                            hasProfile = true
                                        }
                                        .navigationBarBackButtonHidden(true)
                                    } label: {
                                        RowCard(
                                            icon: "person.badge.plus",
                                            iconBg: Color.blue.opacity(0.12),
                                            iconFg: Color.blue,
                                            title: "Make a Profile",
                                            subtitle:
                                                "Create your volunteer profile"
                                        )
                                    }
                                }

                            }
                            .padding(.horizontal)

                            LocationMapCard()
                        }
                    }
                }
                
                if lookingForUsers && !pendingRequests.isEmpty {
                    let currentRequest = pendingRequests[currentRequestIndex]
                    ProfilePopupCard(
                        isPresented: $lookingForUsers,
                        helpRequest: HelpRequest(
                            name: currentRequest.userName,
                            phone: nil, // you don't have phone in PendingHelpRequest
                            urgency: .low, // or map from something if you add urgency later
                            about: currentRequest.situationText,
                            avatarSystemImageRaw: "person.crop.circle.fill"
                        ),
                        onDecline: {
                            showNextRequest()
                        },
                        onAccept: {
                            acceptRequest(currentRequest)
                        }
                    )

                }
                
                // Error alert
                if let error = errorMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding()
                        }
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(10)
                        .padding()
                    }
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                errorMessage = nil
                            }
                        }
                    }
                }
            }
        }
        .task {
            await checkProfileStatus()
        }
        .refreshable {
            await checkProfileStatus()
        }
    }
    
    @MainActor
    private func checkProfileStatus() async {
        guard auth.isLoggedIn && !auth.email.isEmpty else {
            isLoadingProfile = false
            hasProfile = false
            return
        }
        
        isLoadingProfile = true
        errorMessage = nil
        
        do {
            hasProfile = try await VolunteerService.shared.checkVolunteerProfile(email: auth.email)
        } catch {
            print("Error checking profile: \(error.localizedDescription)")
            errorMessage = "Failed to load profile status"
            hasProfile = false
        }
        
        isLoadingProfile = false
    }
    
    @MainActor
    private func fetchPendingRequests() async {
        do {
            pendingRequests = try await VolunteerService.shared.getPendingRequests()
            currentRequestIndex = 0
            
            if pendingRequests.isEmpty {
                errorMessage = "No pending requests at the moment"
                lookingForUsers = false
            }
        } catch {
            print("Error fetching requests: \(error)")
            errorMessage = "Failed to load help requests"
            lookingForUsers = false
        }
    }
    
    private func showNextRequest() {
        if currentRequestIndex < pendingRequests.count - 1 {
            currentRequestIndex += 1
        } else {
            // No more requests
            lookingForUsers = false
            pendingRequests = []
            currentRequestIndex = 0
        }
    }
    
    private func acceptRequest(_ request: PendingHelpRequest) {
        print("✅ Accepted request: \(request.requestId)")
        // TODO: Call backend to assign volunteer to request
        lookingForUsers = false
    }
}

// Keep all your other components below (StatsCard, RowCard, LocationMapCard, etc.)
private struct StatsCard: View {
    let icon: String
    let iconBg: Color
    let iconFg: Color
    let value: String
    let label: String
    let plusColor: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(iconBg)
                        .frame(width: 58, height: 58)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(iconFg)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(label)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

struct RowCard: View {
    let icon: String
    let iconBg: Color
    let iconFg: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconBg)
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconFg)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

struct LocationMapCard: View {
    @StateObject private var lm = LocationManager()
    
    @State private var destinationCoordinate: CLLocationCoordinate2D? = nil
    @State private var destinationName: String = "Destination"

    private let fallback = CLLocationCoordinate2D(
        latitude: 40.7128,
        longitude: -74.0060
    )

    private var centerCoord: CLLocationCoordinate2D {
        destinationCoordinate ?? lm.coordinate ?? fallback
    }

    private var regionBinding: Binding<MKCoordinateRegion> {
        Binding(
            get: {
                MKCoordinateRegion(
                    center: centerCoord,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.03,
                        longitudeDelta: 0.03
                    )
                )
            },
            set: { _ in }
        )
    }

    private var coordText: String {
        String(
            format: "%.4f, %.4f",
            centerCoord.latitude,
            centerCoord.longitude
        )
    }
    
    private func openInAppleMaps() {
        let coordinate = destinationCoordinate ?? lm.coordinate ?? fallback
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = destinationName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    var body: some View {
        Button(action: openInAppleMaps) {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Map(
                        coordinateRegion: regionBinding,
                        showsUserLocation: lm.isAuthorized
                    )
                    .disabled(true)

                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.16), Color.green.opacity(0.10),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .allowsHitTesting(false)

                    GridOverlay(spacing: 42, lineOpacity: 0.10)
                        .allowsHitTesting(false)

                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05), Color.white.opacity(0.0),
                            Color.white.opacity(0.22),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)

                    if lm.showDeniedBanner {
                        DeniedBanner(text: "Location access denied")
                            .padding(.top, 18)
                            .padding(.horizontal, 18)
                    }

                    VStack {
                        Spacer()

                        Button {
                            if lm.isAuthorized {
                                lm.requestOneShotLocation()
                            } else {
                                lm.requestPermission()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.10))
                                    .frame(width: 170, height: 170)

                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 92, height: 92)
                                    .shadow(
                                        color: Color.black.opacity(0.10),
                                        radius: 10,
                                        x: 0,
                                        y: 6
                                    )

                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 66, height: 66)

                                Image(systemName: "location.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }

                        Spacer()
                    }
                    .padding(.bottom, 22)
                }
                .frame(height: 290)
                .clipped()

                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.blue.opacity(0.14))
                            .frame(width: 56, height: 56)

                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 20, weight: .semibold))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Location")
                            .font(.system(size: 20, weight: .semibold))

                        Text(coordText)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                    
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .background(Color(.systemBackground))
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .onAppear { lm.requestPermission() }
    }
}

struct DeniedBanner: View {
    let text: String

    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(Color(red: 0.45, green: 0.25, blue: 0.10))
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(Color(red: 1.0, green: 0.96, blue: 0.72))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 0.95, green: 0.78, blue: 0.20), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct GridOverlay: View {
    let spacing: CGFloat
    let lineOpacity: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Path { p in
                var x: CGFloat = 0
                while x <= w {
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: h))
                    x += spacing
                }
                var y: CGFloat = 0
                while y <= h {
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: w, y: y))
                    y += spacing
                }
            }
            .stroke(Color.black.opacity(lineOpacity), lineWidth: 1)
        }
    }
}

struct ToggleButton: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Color.blue : Color.gray.opacity(0.35))
                    .frame(width: 52, height: 30)

                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .padding(2)
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 2,
                        x: 0,
                        y: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

struct VolunteerTop: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .semibold))  // Adjust size/weight
                    .foregroundColor(Color.gray)
            }

            Spacer()

            VStack {
                Text("Volunteer Dashboard")
                    .font(.system(size: 24, weight: .regular)).bold()

                Text("Welcome back!")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }

            Spacer()
        }
    }
}

