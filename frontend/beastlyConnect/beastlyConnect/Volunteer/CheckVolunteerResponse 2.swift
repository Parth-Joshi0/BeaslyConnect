import Foundation
import UIKit

struct CheckVolunteerResponse: Codable {
    let hasProfile: Bool
    let error: String?
}

struct CheckUserResponse: Codable {
    let hasProfile: Bool
    let error: String?
}

struct CreateUpdateProfileResponse: Codable {
    let success: Bool
    let message: String
}

struct CreateUpdateUserProfileResponse: Codable {
    let success: Bool
    let message: String
}

struct VolunteerProfileData: Codable {
    let email: String
    let fullName: String
    let phoneNumber: String
    let certifications: [String]
    let age: String
    let gender: String
    let weight: String
    let height: String
    let ownsCar: Bool
    let licensePlate: String?
    let carMake: String?
    let carColor: String?
    let profileImage: String?  // Base64 encoded image
}

struct UserProfileData: Codable {
    let email: String
    let fullName: String
    let age: String
    let height: String
    let weight: String
    let condition: String?
    let genderPreference: String?
    let profileImage: String?
}

struct HelpRequestData: Codable {
    let email: String
    let situationText: String
    let voiceRecording: String?  // Base64 encoded audio
}

struct SubmitHelpRequestResponse: Codable {
    let success: Bool
    let requestId: String
    let message: String
}

struct PendingHelpRequest: Codable, Identifiable {
    let requestId: String
    let userEmail: String
    let situationText: String
    let hasVoiceRecording: Bool
    let timestamp: String
    let userName: String
    let userAge: Int?
    let userCondition: String
    let userGenderPreference: String
    
    var id: String { requestId }
}

struct GetPendingRequestsResponse: Codable {
    let requests: [PendingHelpRequest]
}

enum VolunteerServiceError: Error, LocalizedError {
    case badURL
    case badStatus(Int, String)
    case decodeFailed(String)

    var errorDescription: String? {
        switch self {
        case .badURL: return "Bad URL"
        case .badStatus(let code, let body): return "Server returned \(code): \(body)"
        case .decodeFailed(let msg): return "Decode failed: \(msg)"
        }
    }
}

final class VolunteerService {
    static let shared = VolunteerService()
    private init() {}

    private let baseURL = "https://beaslyconnect.onrender.com"

    /// ✅ Flip this on during development if you want ZERO network calls
    var offlineMode: Bool = false

    /// ✅ When server is down, choose to fallback instead of throwing
    var fallbackWhenOffline: Bool = true

    // MARK: - Generic request helper

    private func sendJSONRequest<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        body: Body? = nil,
        headers: [String: String] = [:],
        timeout: TimeInterval = 60
    ) async throws -> Response {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw VolunteerServiceError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (k, v) in headers {
            request.setValue(v, forHTTPHeaderField: k)
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body) // ✅ no try!
        }

        print("📤 \(method) \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        let raw = String(data: data, encoding: .utf8) ?? ""
        print("📥 Raw response: \(raw)")

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw VolunteerServiceError.badStatus(http.statusCode, raw)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw VolunteerServiceError.decodeFailed(raw)
        }
    }

    // MARK: - Your endpoints (with offline fallbacks)

    func checkVolunteerProfile(email: String) async throws -> Bool {
        if offlineMode { return false } // 👈 choose whatever default you want

        struct Body: Codable { let email: String }

        do {
            let response: CheckVolunteerResponse = try await sendJSONRequest(
                path: "/CheckVol",
                method: "POST",
                body: Body(email: email),
                timeout: 60
            )
            return response.hasProfile
        } catch {
            print("⚠️ checkVolunteerProfile failed: \(error.localizedDescription)")
            if fallbackWhenOffline { return false }
            throw error
        }
    }

    func checkUser(email: String) async throws -> Bool {
        if offlineMode { return false }

        struct Body: Codable { let email: String }

        do {
            let response: CheckUserResponse = try await sendJSONRequest(
                path: "/checkUser",
                method: "POST",
                body: Body(email: email),
                headers: ["X-User-Email": email],
                timeout: 60
            )
            if let err = response.error { print("⚠️ Server error: \(err)") }
            return response.hasProfile
        } catch {
            print("⚠️ checkUser failed: \(error.localizedDescription)")
            if fallbackWhenOffline { return false }
            throw error
        }
    }

    func createOrUpdateProfile(
        email: String,
        fullName: String,
        phoneNumber: String,
        certifications: [String],
        age: String,
        gender: String,
        weight: String,
        height: String,
        ownsCar: Bool,
        licensePlate: String?,
        carMake: String?,
        carColor: String?,
        profileImage: UIImage?
    ) async throws -> Bool {
        if offlineMode { return true } // pretend success offline

        var imageBase64: String?
        if let image = profileImage, let data = image.jpegData(compressionQuality: 0.7) {
            imageBase64 = data.base64EncodedString()
        }

        let profileData = VolunteerProfileData(
            email: email,
            fullName: fullName,
            phoneNumber: phoneNumber,
            certifications: certifications,
            age: age,
            gender: gender,
            weight: weight,
            height: height,
            ownsCar: ownsCar,
            licensePlate: licensePlate,
            carMake: carMake,
            carColor: carColor,
            profileImage: imageBase64
        )

        do {
            let response: CreateUpdateProfileResponse = try await sendJSONRequest(
                path: "/CreateUpdateProfile",
                method: "POST",
                body: profileData,
                timeout: 60
            )
            return response.success
        } catch {
            print("⚠️ createOrUpdateProfile failed: \(error.localizedDescription)")
            if fallbackWhenOffline { return true }
            throw error
        }
    }

    func createOrUpdateUserProfile(
        email: String,
        fullName: String,
        age: String,
        height: String,
        weight: String,
        condition: String?,
        genderPreference: String?,
        profileImage: UIImage?
    ) async throws -> Bool {
        if offlineMode { return true }

        var imageBase64: String?
        if let image = profileImage, let data = image.jpegData(compressionQuality: 0.7) {
            imageBase64 = data.base64EncodedString()
        }

        let profileData = UserProfileData(
            email: email,
            fullName: fullName,
            age: age,
            height: height,
            weight: weight,
            condition: condition,
            genderPreference: genderPreference,
            profileImage: imageBase64
        )

        do {
            let response: CreateUpdateUserProfileResponse = try await sendJSONRequest(
                path: "/CreateUpdateUserProfile",
                method: "POST",
                body: profileData,
                timeout: 60
            )
            return response.success
        } catch {
            print("⚠️ createOrUpdateUserProfile failed: \(error.localizedDescription)")
            if fallbackWhenOffline { return true }
            throw error
        }
    }

    func submitHelpRequest(
        email: String,
        situationText: String,
        voiceRecordingURL: URL?
    ) async throws -> String {
        if offlineMode { return "offline-\(UUID().uuidString)" }

        var voiceBase64: String?
        if let url = voiceRecordingURL {
            let data = try Data(contentsOf: url)
            print("📤 Audio file size: \(data.count) bytes")
            voiceBase64 = data.base64EncodedString()
        }

        let helpRequestData = HelpRequestData(
            email: email,
            situationText: situationText,
            voiceRecording: voiceBase64
        )

        do {
            let response: SubmitHelpRequestResponse = try await sendJSONRequest(
                path: "/SubmitHelpRequest",
                method: "POST",
                body: helpRequestData,
                timeout: 120
            )
            return response.requestId
        } catch {
            print("⚠️ submitHelpRequest failed: \(error.localizedDescription)")
            if fallbackWhenOffline { return "offline-\(UUID().uuidString)" }
            throw error
        }
    }

    func getPendingRequests() async throws -> [PendingHelpRequest] {
        if offlineMode { return Self.mockPendingRequests() }

        do {
            let response: GetPendingRequestsResponse = try await sendJSONRequest(
                path: "/GetPendingRequests",
                method: "GET",
                body: Optional<Int>.none as Int?, // no body
                timeout: 60
            )
            return response.requests
        } catch {
            print("⚠️ getPendingRequests failed: \(error.localizedDescription)")
            if fallbackWhenOffline { return Self.mockPendingRequests() }
            throw error
        }
    }

    // MARK: - Mock data

    private static func mockPendingRequests() -> [PendingHelpRequest] {
        [
            PendingHelpRequest(
                requestId: "mock-1",
                userEmail: "user1@test.com",
                situationText: "Need help picking up groceries.",
                hasVoiceRecording: false,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                userName: "Goblin1",
                userAge: 72,
                userCondition: "Limited mobility",
                userGenderPreference: "Prefer not to say"
            ),
            PendingHelpRequest(
                requestId: "mock-2",
                userEmail: "user2@test.com",
                situationText: "Ride to pharmacy needed.",
                hasVoiceRecording: true,
                timestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                userName: "Goblin2",
                userAge: nil,
                userCondition: "N/A",
                userGenderPreference: "Female volunteer preferred"
            )
        ]
    }
}
