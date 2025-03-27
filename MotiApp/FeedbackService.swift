import Foundation
import FirebaseFirestore
import UIKit

class FeedbackService {
    // Get a reference to the Firestore database
    static let db = Firestore.firestore()
    
    /// Sends user feedback to Firebase Firestore
    /// - Parameters:
    ///   - text: The feedback text content
    ///   - type: The type of feedback (General, Bug Report, Feature, Question)
    ///   - email: Optional contact email
    ///   - includeDeviceInfo: Whether to include device information
    /// - Returns: Boolean indicating success
    static func sendFeedback(text: String, type: String, email: String, includeDeviceInfo: Bool) async throws -> Bool {
        // Create the basic feedback document
        var feedbackData: [String: Any] = [
            "text": text,
            "type": type,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        // Add optional contact email if provided
        if !email.isEmpty {
            feedbackData["email"] = email
        }
        
        // Add device info if requested
        if includeDeviceInfo {
            feedbackData["deviceInfo"] = [
                "device": UIDevice.current.model,
                "os": UIDevice.current.systemName,
                "osVersion": UIDevice.current.systemVersion,
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
                "buildVersion": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
                "idiom": UIDevice.current.userInterfaceIdiom.description
            ]
        }
        
        // Send to Firestore
        do {
            _ = try await db.collection("feedback").addDocument(data: feedbackData)
            
            // Log analytics event if needed
            // Analytics.logEvent("feedback_submitted", parameters: ["type": type])
            
            return true
        } catch {
            print("Error sending feedback: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// For testing purposes - get all feedback (in real app, this would be admin-only)
    static func getAllFeedback() async throws -> [Feedback] {
        let snapshot = try await db.collection("feedback").order(by: "timestamp", descending: true).getDocuments()
        
        return snapshot.documents.compactMap { document -> Feedback? in
            let data = document.data()
            
            guard let text = data["text"] as? String,
                  let type = data["type"] as? String else {
                return nil
            }
            
            let email = data["email"] as? String ?? ""
            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            
            return Feedback(
                id: document.documentID,
                text: text,
                type: type,
                email: email,
                timestamp: timestamp
            )
        }
    }
}

// Model to represent feedback items
struct Feedback: Identifiable {
    var id: String
    var text: String
    var type: String
    var email: String
    var timestamp: Date
    
    // Helper property to format the date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// Extension to get a description for UIUserInterfaceIdiom
extension UIUserInterfaceIdiom {
    var description: String {
        switch self {
        case .phone: return "iPhone"
        case .pad: return "iPad"
        case .tv: return "Apple TV"
        case .carPlay: return "CarPlay"
        case .mac: return "Mac"
        case .vision: return "Apple Vision"
        case .unspecified: return "unspecified"
        @unknown default: return "unknown"
        }
    }
}
