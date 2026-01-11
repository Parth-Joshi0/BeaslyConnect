//
//  UserPage.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-10.
//

import SwiftUI

struct UserView: View {
    @EnvironmentObject var auth: AuthState
    
    @State private var hasUserProfile: Bool = false
    @State private var isLoadingProfile: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if isLoadingProfile {
                ProgressView("Checking profile...")
                    .scaleEffect(1.2)
            } else {
                ScrollView {
                    TopHeader(titleText: "Welcome Home! 👋", secondaryText: "We're here to help you")

                    Divider()

                    Spacer(minLength: 24)
                    
                    if hasUserProfile {
                        
                        GradientActionCard(
                            title: "Need Help?",
                            subtitle: "We'll connect you with a volunteer nearby",
                            buttonText: "Ask for Help",
                            icon: "heart",
                            gradient: LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            destination: AskForHelp()
                        )
                        
                        InfoActionCard(
                            title: "Update Your Profile",
                            subtitle: "Help volunteers understand your needs better",
                            buttonText: "Edit Profile",
                            icon: "person.crop.circle",
                            gradient: LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            destination: UserProfile(mode: .update){
                                hasUserProfile = true
                            }
                        )
                        
                        Spacer(minLength: 24)
                    } else {
                        
                        InfoActionCard(
                            title: "Create Your Profile",
                            subtitle: "Help volunteers understand your needs better",
                            buttonText: "Set Up Profile",
                            icon: "person.crop.circle",
                            gradient: LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            destination: UserProfile(mode: .create){
                                hasUserProfile = true
                            }
                        )
                    }

                    Spacer(minLength: 24)

                    Text("Support & Resources").font(
                        .system(size: 22, weight: .semibold)
                    )
                    .foregroundStyle(.gray)
                    .padding(.top, 6)

                    Spacer(minLength: 24)

                    NavigationLink {
                        UserResourcesAndTips()
                            .navigationBarBackButtonHidden(true)
                    } label: {
                        RowCard(
                            icon: "book.fill",
                            iconBg: Color.yellow,
                            iconFg: Color.white,
                            title: "Resources & Tips",
                            subtitle: "Helpful guides and information"
                        )
                    }

                    Spacer(minLength: 24)

                    infoCard(
                        text: "💜 You're not alone. Our community of caring volunteers is here to support you whenever you need help."
                    )
                }
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
            hasUserProfile = false
            return
        }
        
        isLoadingProfile = true
        errorMessage = nil
        
        do {
            hasUserProfile = try await VolunteerService.shared.checkUser(email: auth.email)
        } catch {
            print("Error checking user profile: \(error.localizedDescription)")
            errorMessage = "Failed to load profile status"
            hasUserProfile = false
        }
        
        isLoadingProfile = false
    }
}

struct TopHeader: View {
    @Environment(\.dismiss) var dismiss
    
    let titleText: String
    let secondaryText: String

    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .semibold))  // Adjust size/weight
                    .foregroundColor(Color.gray)
            }

            Spacer()

            VStack {
                Text(titleText)
                    .font(.system(size: 24, weight: .regular)).bold()

                Text(secondaryText)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }

            Spacer()
        }
    }
}

struct infoCard: View {
    let text: String

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 14) {

                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundStyle(.gray)
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
}

struct GradientActionCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let buttonText: String
    let icon: String
    let gradient: LinearGradient
    let destination: Destination

    init(
        title: String,
        subtitle: String,
        buttonText: String,
        icon: String,
        gradient: LinearGradient,
        destination: Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.buttonText = buttonText
        self.icon = icon
        self.gradient = gradient
        self.destination = destination
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.25))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            NavigationLink(
                destination: destination.navigationBarBackButtonHidden(true)
            ) {
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
        }
        .padding(24)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
    }
}

struct InfoActionCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let buttonText: String
    let icon: String
    let gradient: LinearGradient
    let destination: Destination

    var body: some View {
        VStack(spacing: 20) {

            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(gradient)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            NavigationLink(
                destination: destination.navigationBarBackButtonHidden(true)
            ) {
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(gradient)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }
}
