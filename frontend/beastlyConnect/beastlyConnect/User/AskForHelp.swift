//
//  AskForHelp.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-11.
//

import AVFoundation
import Foundation
import SwiftUI

struct AskForHelp: View {
    @EnvironmentObject var auth: AuthState
    @StateObject private var voiceRecorder = VoiceRecorder()
    @State private var situationText = ""
    @State private var navigateToVolunteerFound = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            TopHeader(
                titleText: "Ask for Help",
                secondaryText: "We'll connect you with a volunteer"
            )
            Divider()

            Spacer(minLength: 24)

            VoiceMessageCard(voiceRecorder: voiceRecorder)

            Spacer(minLength: 24)

            DescribeSituationCard(text: $situationText, isEditable: true)

            Spacer(minLength: 24)
            
            NavigationLink(
                destination: VolunteerFound().navigationBarBackButtonHidden(true),
                isActive: $navigateToVolunteerFound
            ) {
                EmptyView()
            }
            
            GradientSubmitButton(
                isEnabled: !situationText.isEmpty,
                isLoading: isSubmitting
            ) {
                Task {
                    await submitHelpRequest()
                }
            }

            Spacer(minLength: 24)

            Text(
                "A nearby volunteer will be notified and will reach out to you soon. You'll receive a notification when someone accepts your request."
            )
            .foregroundColor(Color(red: 0.45, green: 0.50, blue: 0.60))
            .multilineTextAlignment(.center)
            .font(.system(size: 17, weight: .regular))
            .lineSpacing(4)
            
            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.99))
        )
    }
    
    @MainActor
    private func submitHelpRequest() async {
        isSubmitting = true
        errorMessage = nil
        
        do {
            let requestId = try await VolunteerService.shared.submitHelpRequest(
                email: auth.email,
                situationText: situationText,
                voiceRecordingURL: voiceRecorder.recordedURL
            )
            
            print("✅ Help request submitted with ID: \(requestId)")
            navigateToVolunteerFound = true
            
        } catch {
            print("❌ Error submitting help request: \(error)")
            errorMessage = "Failed to submit request. Please try again."
        }
        
        isSubmitting = false
    }
}

struct VoiceMessageCard: View {
    @ObservedObject var voiceRecorder: VoiceRecorder

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Voice Message (Optional)")
                .font(.headline)
                .foregroundColor(.primary)

            // Error Message
            if let error = voiceRecorder.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Recording Button
            Button(action: {
                Task {
                    if voiceRecorder.isRecording {
                        voiceRecorder.stop()
                    } else {
                        await voiceRecorder.start()
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: voiceRecorder.isRecording
                                    ? [Color.red, Color.red.opacity(0.8)]
                                    : [Color.orange, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 6)

                    Image(
                        systemName: voiceRecorder.isRecording
                            ? "stop.fill" : "mic.fill"
                    )
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            // Status Text
            Text(
                voiceRecorder.isRecording
                    ? "Recording... Tap to stop"
                    : "Tap to record a voice message"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)

            // Playback Controls (shown when recording exists)
            if voiceRecorder.recordedURL != nil {
                Divider()
                    .padding(.vertical, 8)

                VStack(spacing: 12) {
                    Text("Recording saved!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)

                    HStack(spacing: 20) {
                        // Play Button
                        Button(action: {
                            voiceRecorder.play()
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 24))
                                Text("Play")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)

                        // Stop Playback Button
                        Button(action: {
                            voiceRecorder.stopPlayback()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 24))
                                Text("Stop")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Reset Button
                    Button(action: {
                        voiceRecorder.reset()
                    }) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 20))
                            Text("Delete Recording")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct DescribeSituationCard: View {
    var title: String = "Describe Your Situation"
    var subtitle: String = "Tell us what kind of help you need"

    @Binding var text: String
    var isEditable: Bool = true

    var placeholder: String =
        "Example: I need help with grocery shopping, or I need a ride to a doctor's appointment..."

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)

            contentBox
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.blue.opacity(0.35), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var contentBox: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )

            if isEditable {
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary.opacity(0.75))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .padding(.trailing, 8)
                }

                TextEditor(text: $text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.body)

            } else {
                let display = text.trimmingCharacters(in: .whitespacesAndNewlines)

                Text(display.isEmpty ? "No description provided." : display)
                    .foregroundColor(display.isEmpty ? .secondary : .primary)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 140, alignment: .topLeading)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

struct GradientSubmitButton: View {
    var title: String = "Submit Help Request"
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button {
            if isEnabled && !isLoading {
                action()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(isEnabled ? 1.0 : 0.6)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(height: 56)
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
        .padding(.horizontal)
        .disabled(!isEnabled || isLoading)
    }
}
