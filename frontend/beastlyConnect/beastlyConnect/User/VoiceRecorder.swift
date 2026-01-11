//
//  VoiceRecorder.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-11.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class VoiceRecorder: ObservableObject {
    
    @Published var isRecording = false
        @Published var recordedURL: URL? = nil
        @Published var errorMessage: String? = nil

        private var recorder: AVAudioRecorder?
        private var player: AVAudioPlayer?

    func requestPermission() async -> Bool {
        let session = AVAudioSession.sharedInstance()
        return await withCheckedContinuation { cont in
            session.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }

    private func outputURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("voiceMessage.m4a")
    }

    func start() async {
        errorMessage = nil

        let granted = await requestPermission()
        guard granted else {
            errorMessage = "Microphone permission denied."
            return
        }

        let session = AVAudioSession.sharedInstance()

        do {
            // Configure audio session
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = outputURL()

            // AAC in .m4a
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.prepareToRecord()
            recorder?.record()

            isRecording = true
            recordedURL = nil
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    func stop() {
        guard isRecording else { return }
        recorder?.stop()
        recorder = nil
        isRecording = false
        recordedURL = outputURL()
    }

    func reset() {
        stop()
        recordedURL = nil
        errorMessage = nil
        // Optionally delete file
        let url = outputURL()
        try? FileManager.default.removeItem(at: url)
    }
    
    func play() {
            guard let url = recordedURL else { return }
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.play()
            } catch {
                errorMessage = "Failed to play recording: \(error.localizedDescription)"
            }
        }

        func stopPlayback() {
            player?.stop()
            player = nil
        }
}
