//
//  UserProfile.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-11.
//

import PhotosUI
import SwiftUI

struct UserProfile: View {
    @EnvironmentObject var auth: AuthState
    
    let mode: ProfileMode
    let onComplete: () -> Void

    var title: String { mode == .create ? "Make a Profile" : "Update Profile" }
    @Environment(\.dismiss) var dismiss
    
    @State private var fullName = ""
    @State private var profileImage: UIImage? = nil
    @State private var age = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var isSaving = false
    @State private var condition = ""
    @State private var pref: Gender = .preferNotToSay

    var body: some View {
        ScrollView {
            TopHeader(
                titleText: title,
                secondaryText: "Help us understand your needs"
            )

            Divider()
            Spacer(minLength: 24)

            ProfileImageCard(image: $profileImage)
                .padding(.horizontal)
                .padding(.top, 8)
            
            Spacer(minLength: 24)

            FormSectionCard(
                icon: "person.fill",
                iconGradient: LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                title: "Basic Information",
            ) {
                VStack(spacing: 18) {
                    LabeledTextFieldRow(
                        label: "Full Name",
                        placeholder: "Enter your full name",
                        required: true,
                        keyboard: .default,
                        text: $fullName
                    )
                    LabeledTextFieldRow(
                        label: "Age",
                        placeholder: "Enter your age",
                        required: true,
                        keyboard: .numberPad,
                        text: $age
                    )
                    LabeledTextFieldRow(
                        label: "Height",
                        placeholder: #"e.g., 5'8" or 173 cm"#,
                        required: true,
                        keyboard: .default,
                        text: $height
                    )
                    LabeledTextFieldRow(
                        label: "Weight",
                        placeholder: "e.g., 150 lbs or 68 kg",
                        required: true,
                        keyboard: .default,
                        text: $weight
                    )
                }
            }
            
            Spacer(minLength: 24)

            FormSectionCard(
                icon: "info.circle.fill",
                iconGradient: LinearGradient(
                    colors: [.blue.opacity(0.85), .purple.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                title: "Additional Information",
                subtitle: "These fields are optional but help us serve you better",
            ) {
                VStack(spacing: 18) {
                    LabeledTextEditorRow(
                        label: "Any Autoimmune Disease/Impairment",
                        placeholder: "Please share any conditions we should be aware of",
                        text: $condition
                    )

                    LabeledPickerRow(
                        label: "Gender Preference for Volunteer",
                        options: Gender.allCases,
                        optionLabel: { $0.rawValue },
                        selection: $pref
                    )
                }
            }
            
            Spacer(minLength: 24)

            PrimaryProfileButton(mode: mode, isLoading: isSaving) {
                Task {
                    await saveProfile()
                }
            }
            
            Spacer(minLength: 24)
        }
    }
    
    @MainActor
    private func saveProfile() async {
        isSaving = true
        
        do {
            let success = try await VolunteerService.shared.createOrUpdateUserProfile(
                email: auth.email,
                fullName: fullName,
                age: age,
                height: height,
                weight: weight,
                condition: condition.isEmpty ? nil : condition,
                genderPreference: pref.rawValue,
                profileImage: profileImage
            )
            
            if success {
                onComplete()
                dismiss()
            }
        } catch {
            print("Error saving user profile: \(error)")
        }
        
        isSaving = false
    }
}

struct FormSectionCard<Content: View>: View {
    let icon: String
    let iconGradient: LinearGradient
    let title: String
    let subtitle: String?

    @ViewBuilder let content: Content

    init(
        icon: String,
        iconGradient: LinearGradient,
        title: String,
        subtitle: String? = nil,
        borderColor: Color = Color.purple.opacity(0.25),
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.iconGradient = iconGradient
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(iconGradient)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            content
        }
        .padding(22)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
    }
}

struct LabeledTextFieldRow: View {
    let label: String
    let placeholder: String
    var required: Bool = false
    var keyboard: UIKeyboardType = .default

    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if required {
                    Text("*")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.pink)
                }
            }

            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                )
        }
    }
}

struct LabeledTextEditorRow: View {
    let label: String
    let placeholder: String
    var optionalTag: String = "(Optional)"

    @Binding var text: String

    @State private var editorHeight: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(optionalTag)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                // Placeholder
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
            )
        }
    }
}

struct LabeledPickerRow<Option: Hashable>: View {
    let label: String
    var optionalTag: String = "(Optional)"
    let options: [Option]
    let optionLabel: (Option) -> String

    @Binding var selection: Option

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(optionalTag)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { o in
                    Text(optionLabel(o)).tag(o)
                }
            }
            .pickerStyle(.menu)
            .tint(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
            )
        }
    }
}

struct ProfileImageCard: View {
    @State private var selectedItem: PhotosPickerItem?
    @Binding var image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile Picture")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 160, height: 160)

                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 160)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(Color.gray.opacity(0.6))
                    }
                }

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .offset(x: 6, y: 6)
            }
            .frame(maxWidth: .infinity)

            Text("Click the icon to upload a photo")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .onChange(of: selectedItem) {
            Task {
                if let item = selectedItem,
                   let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    image = uiImage
                }
            }
        }
    }
}
