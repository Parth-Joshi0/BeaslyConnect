//
//  VolunteerProfile.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-10.
//

import SwiftUI
import PhotosUI

enum ProfileMode {
    case create
    case update
}

enum Gender: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non-binary"
    case preferNotToSay = "Prefer not to say"

    var id: String { rawValue }
}

struct VolunteerProfile: View {
    @EnvironmentObject var auth: AuthState
    
    let mode: ProfileMode
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var profileImage: UIImage? = nil
    @State private var fullName = ""
    @State private var number = ""
    @State private var age = ""
    @State private var gender: Gender? = nil
    @State private var weight = ""
    @State private var height = ""
    @State private var selectedCertifications: Set<String> = []
    @State private var otherCertifications = ""
    @State private var ownsCar = false
    @State private var licensePlate = ""
    @State private var carMake = ""
    @State private var carColor = ""
    @State private var isSaving = false

    var title: String { mode == .create ? "Make a Profile" : "Update Profile" }

    var body: some View {
        ScrollView {
            VStack{
                VolunteerProfileTop(mode: mode, title: title)
                
                Divider()
                
                ProfileImageCard(image: $profileImage).padding(.horizontal)
                    .padding(.top, 8)
                
                Spacer(minLength: 20)
                
                FullRowCard(title: "Full Name", placeholder: "Enter your name", text: $fullName)
                    .padding(.horizontal)
                
                FullRowCard(title: "Phone Number", placeholder: "Enter your phone number", text: $number)
                    .padding(.horizontal)
                
                CertificationsCard(
                    selectedCertifications: $selectedCertifications,
                    otherCertifications: $otherCertifications
                )
                .padding(.horizontal)
                
                HStack(spacing: 14) {
                    HalfRowFieldCard(
                            title: "Age",
                            placeholder: "25",
                            frameHeight: 0,
                            text: $age
                        )

                    HalfRowDropdownCard(
                            title: "Gender",
                            placeholder: "Select",
                            options: Gender.allCases,
                            label: { $0.rawValue },
                            selection: $gender
                        )
                }.padding(.horizontal)
                
                HStack(spacing: 14) {
                    HalfRowFieldCard(
                            title: "Weight (lbs)",
                            placeholder: "150",
                            frameHeight: 66,
                            text: $weight,
                            keyboard: .default
                        )

                    HalfRowFieldCard(
                            title: "Height (inches)",
                            placeholder: "68",
                            frameHeight: 66,
                            text: $height,
                            keyboard: .default
                        )
                }.padding(.horizontal)
                
                CarInformationCard(
                    ownsCar: $ownsCar,
                    licensePlate: $licensePlate,
                    carMake: $carMake,
                    carColor: $carColor
                )
                .padding(.horizontal)
                
                PrimaryProfileButton(mode: mode, isLoading: isSaving) {
                    Task {
                        await saveProfile()
                    }
                }

            }
        }
    }
    
    @MainActor
    private func saveProfile() async {
        isSaving = true
        
        // Combine selected certifications with other certifications
        var allCertifications = Array(selectedCertifications)
        if !otherCertifications.isEmpty {
            allCertifications.append(otherCertifications)
        }
        
        do {
            let success = try await VolunteerService.shared.createOrUpdateProfile(
                email: auth.email,
                fullName: fullName,
                phoneNumber: number,
                certifications: allCertifications,
                age: age,
                gender: gender?.rawValue ?? "",
                weight: weight,
                height: height,
                ownsCar: ownsCar,
                licensePlate: ownsCar ? licensePlate : nil,
                carMake: ownsCar ? carMake : nil,
                carColor: ownsCar ? carColor : nil,
                profileImage: profileImage
            )
            
            if success {
                onComplete()
                dismiss()
            }
        } catch {
            print("Error saving profile: \(error)")
        }
        
        isSaving = false
    }
}

struct VolunteerProfileTop: View {
    let mode: ProfileMode
    let title: String
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.black)
            }

            Spacer()

            Text(title)
                .font(.system(size: 24, weight: .regular))
                .bold()

            Spacer()
        }
    }
}

struct FullRowCard: View {
    let title: String
        let placeholder: String
        @Binding var text: String

        var keyboard: UIKeyboardType = .default
        var textContentType: UITextContentType? = nil
        var autocapitalization: TextInputAutocapitalization = .words
        var submitLabel: SubmitLabel = .done

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .submitLabel(submitLabel)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                    )
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
        }
}

struct HalfRowFieldCard: View {
    let title: String
    let placeholder: String
    let frameHeight: CGFloat
    @Binding var text: String

    var keyboard: UIKeyboardType = .numberPad
    var textAlignment: TextAlignment = .leading

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(minHeight: frameHeight)

            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .multilineTextAlignment(textAlignment)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                )
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
        .frame(maxWidth: .infinity) // key for half-row
    }
}

struct HalfRowDropdownCard<T: Hashable & Identifiable>: View {
    let title: String
    let placeholder: String
    let options: [T]
    let label: (T) -> String

    @Binding var selection: T?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(minWidth: 40)

            Menu {
                ForEach(options) { option in
                    Button {
                        selection = option
                    } label: {
                        Text(label(option))
                    }
                }
            } label: {
                HStack {
                    Text(selection.map(label) ?? placeholder)
                        .foregroundStyle(selection == nil ? .secondary : .primary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
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
        .frame(maxWidth: .infinity)
    }
}

struct CertificationsCard: View {
    @Binding var selectedCertifications: Set<String>
    @Binding var otherCertifications: String
    
    let certificationOptions = [
        ["CPR Training", "Medical Certification"],
        ["Driver's License", "First Aid Certification"]
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Certifications")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            
            // First row of bubbles
            HStack(spacing: 12) {
                ForEach(certificationOptions[0], id: \.self) { cert in
                    CertificationBubble(
                        title: cert,
                        isSelected: selectedCertifications.contains(cert)
                    ) {
                        toggleCertification(cert)
                    }
                }
            }
            
            // Second row of bubbles
            HStack(spacing: 12) {
                ForEach(certificationOptions[1], id: \.self) { cert in
                    CertificationBubble(
                        title: cert,
                        isSelected: selectedCertifications.contains(cert)
                    ) {
                        toggleCertification(cert)
                    }
                }
            }
            
            // Other certifications text field
            TextField("Other certs", text: $otherCertifications)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                )
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
    }
    
    private func toggleCertification(_ cert: String) {
        if selectedCertifications.contains(cert) {
            selectedCertifications.remove(cert)
        } else {
            selectedCertifications.insert(cert)
        }
    }
}

struct CertificationBubble: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? Color.blue : Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct CarInformationCard: View {
    @Binding var ownsCar: Bool
    @Binding var licensePlate: String
    @Binding var carMake: String
    @Binding var carColor: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Do you have a car?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                Button(action: { ownsCar = true }) {
                    Text("Yes")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ownsCar ? .white : .primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(ownsCar ? Color.blue : Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(ownsCar ? Color.clear : Color.gray.opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                Button(action: { ownsCar = false }) {
                    Text("No")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(!ownsCar ? .white : .primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(!ownsCar ? Color.blue : Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(!ownsCar ? Color.clear : Color.gray.opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            
            if ownsCar {
                VStack(spacing: 12) {
                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                        )
                    
                    TextField("Car Make", text: $carMake)
                        .textInputAutocapitalization(.words)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                        )
                    
                    TextField("Colour", text: $carColor)
                        .textInputAutocapitalization(.words)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                        )
                }
            }
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
    }
}

struct PrimaryProfileButton: View {
    let mode: ProfileMode
    var isLoading: Bool = false
    var action: () -> Void

    private var title: String {
        mode == .create ? "Complete Profile" : "Update Profile"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                
                Text(isLoading ? "Saving..." : title)
                    .font(.system(size: 22, weight: .semibold))
                Image(systemName: mode == .create ? "checkmark" : "arrow.triangle.2.circlepath")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.blue)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.85 : 1.0)
    }
}
