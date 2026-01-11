//
//  UserResourcesAndTips.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-11.
//

import SwiftUI

struct UserResourcesAndTips: View {
    var body: some View {
        ScrollView {
            TopHeader(titleText: "Resources & Tips", secondaryText: "How to use Beasley Connect")
            Divider()
            
            EmergencyWarningCard(
                title: "⚠️ Real Emergencies",
                headline: "Beasley Connect is NOT for life-threatening emergencies!",
                bodyText: "If you are experiencing a medical emergency, fire, crime in progress, or any situation requiring immediate professional help, please call:",
                footer: "Our volunteers are community members, not emergency responders. Your safety comes first! 💜",
                icon: "exclamationmark.triangle.fill",
                callTitle: "911",
                callSubtitle: "Emergency Services",
                phoneNumber: "2897072625",
                gradient: LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            
            Spacer(minLength: 24)
            
            StepsInfoCard(
                headerIcon: "book.fill",
                headerTitle: "How Beasley Connect Works",
                headerGradient: LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                steps: [
                    StepItem(number: 1, title: "Create Your Profile", detail: "Set up your profile so volunteers can better understand your needs. You can include optional info like medical conditions or volunteer preferences."),
                    StepItem(number: 2, title: "Ask for Help", detail: "Describe what you need help with. You can record a voice message, select urgency, and choose categories (groceries, rides, tasks, etc.)."),
                    StepItem(number: 3, title: "Get Matched with a Volunteer", detail: "Nearby verified volunteers are notified. Once someone accepts, you’ll see their profile, live location, and ETA."),
                    StepItem(number: 4, title: "Stay Connected", detail: "Call or message your volunteer through the app. Track progress and get updates when they’re close.")
                ]
            )
            
            Spacer(minLength: 24)

            ChecklistCard(
                headerIcon: "shield.fill",
                headerTitle: "Safety & Trust",
                tint: .green,
                items: [
                    "All volunteers are background-checked and verified",
                    "You can see ratings and reviews before they arrive",
                    "Track your volunteer's location in real-time",
                    "Direct call and message features for easy communication"
                ]
            )
            
            Spacer(minLength: 24)
            
            HelpGridCard(
                headerIcon: "heart.fill",
                headerTitle: "What We Help With",
                tint: .blue,
                categories: [
                    HelpCategory(emoji: "🛒", title: "Grocery Shopping"),
                    HelpCategory(emoji: "🚗", title: "Rides & Transport"),
                    HelpCategory(emoji: "🏠", title: "Household Tasks"),
                    HelpCategory(emoji: "💬", title: "Companionship"),
                    HelpCategory(emoji: "📦", title: "Errands"),
                    HelpCategory(emoji: "🔧", title: "Light Repairs")
                ]
            )
            
            Spacer(minLength: 24)
            
            SupportContactCard(
                                title: "Need help using the app?",
                                subtitle: "Contact our support team at",
                                email: "support@neighbourlink.com"
                            )
            Spacer(minLength: 24)


        }
    }
}

struct EmergencyWarningCard: View {
    let title: String
    let headline: String
    let bodyText: String
    let footer: String
    
    let icon: String               // e.g. "exclamationmark.triangle"
    let callTitle: String          // e.g. "911"
    let callSubtitle: String       // e.g. "Emergency Services"
    let phoneNumber: String        // e.g. "911"
    
    let gradient: LinearGradient
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Text(headline)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(bodyText)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.92))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            
            Button {
                if let url = URL(string: "tel://\(phoneNumber)") {
                    openURL(url)
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(callTitle)
                            .font(.title.weight(.bold))
                        Text(callSubtitle)
                            .font(.subheadline)
                            .opacity(0.9)
                    }
                    
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(18)
                .background(Color.white.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
            
            Text(footer)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(22)
        .background(gradient)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 10)
    }
}

struct StepItem: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let detail: String
}

struct StepsInfoCard: View {
    let headerIcon: String         // e.g. "book"
    let headerTitle: String
    let headerGradient: LinearGradient
    
    let steps: [StepItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            
            HStack(spacing: 14) {
                Image(systemName: headerIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(headerGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Text(headerTitle)
                    .font(.title3.weight(.semibold))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 22) {
                ForEach(steps) { step in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(step.number)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(
                                LinearGradient(colors: [.orange, .pink],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(step.title)
                                .font(.headline.weight(.semibold))
                            Text(step.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(22)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
    }
}

struct ChecklistCard: View {
    let headerIcon: String
    let headerTitle: String
    let tint: Color                // e.g. .green
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: headerIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(tint)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Text(headerTitle)
                    .font(.title3.weight(.semibold))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 14) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(tint)
                            .padding(.top, 2)
                        
                        Text(item)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(22)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(tint.opacity(0.20), lineWidth: 1)
        )
    }
}

struct SupportContactCard: View {
    let title: String
    let subtitle: String
    let email: String
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button(email) {
                if let url = URL(string: "mailto:\(email)") {
                    openURL(url)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.purple)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

struct HelpCategory: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
}

struct HelpCategoryTile: View {
    let emoji: String
    let title: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 28))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .padding(.vertical, 10)
        .background(Color(.systemBackground).opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct HelpGridCard: View {
    let headerIcon: String
    let headerTitle: String
    let tint: Color
    let categories: [HelpCategory]
    
    private let cols = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: headerIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(tint)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Text(headerTitle)
                    .font(.title3.weight(.semibold))
                
                Spacer()
            }
            
            LazyVGrid(columns: cols, spacing: 14) {
                ForEach(categories) { c in
                    HelpCategoryTile(emoji: c.emoji, title: c.title)
                }
            }
        }
        .padding(22)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(tint.opacity(0.20), lineWidth: 1)
        )
    }
}
