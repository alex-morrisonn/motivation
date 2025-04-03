import Foundation
import FirebaseFirestore
import UIKit
import Network

// MARK: - Error Types
/// Custom error types for better error handling in feedback operations
enum FeedbackError: Error, LocalizedError {
    case emptyFeedbackText
    case invalidEmail
    case networkOffline
    case firebaseError(String)
    case rateLimitExceeded
    case timeout
    case serverError(Int)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .emptyFeedbackText:
            return "Feedback text cannot be empty"
        case .invalidEmail:
            return "The provided email address is invalid"
        case .networkOffline:
            return "You appear to be offline. Please check your connection and try again"
        case .firebaseError(let message):
            return "Firebase error: \(message)"
        case .rateLimitExceeded:
            return "Too many feedback submissions. Please try again later"
        case .timeout:
            return "Request timed out. Please try again"
        case .serverError(let code):
            return "Server error occurred (Code: \(code))"
        case .unknownError(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - Result Model
/// Result type for feedback submission
struct FeedbackResult {
    let success: Bool
    let documentID: String?
    let error: FeedbackError?
    let timestamp: Date
    
    static func success(documentID: String) -> FeedbackResult {
        return FeedbackResult(success: true, documentID: documentID, error: nil, timestamp: Date())
    }
    
    static func failure(error: FeedbackError) -> FeedbackResult {
        return FeedbackResult(success: false, documentID: nil, error: error, timestamp: Date())
    }
}

// MARK: - Feedback Model
/// Model to represent feedback items
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

// MARK: - FeedbackService
/// Service responsible for handling user feedback submission and management
class FeedbackService {
    // MARK: - Properties
    
    /// Reference to the Firestore database
    static let db = Firestore.firestore()
    
    /// Network monitor for connectivity checks
    private static let networkMonitor = NWPathMonitor()
    private static var isNetworkAvailable = true
    private static var isMonitoringStarted = false
    
    /// Rate limiting properties
    private static let feedbackRateLimit = 5 // Max submissions in rate limit window
    private static let rateLimitWindow: TimeInterval = 60 * 10 // 10 minutes
    private static var recentSubmissions: [Date] = []
    
    /// Key for UserDefaults to store cached feedback
    private static let cachedFeedbackKey = "com.alexmorrison.moti.cachedFeedback"
    
    // MARK: - Initialization & Setup
    
    /// Start network monitoring
    static func startNetworkMonitoring() {
        if isMonitoringStarted { return }
        
        networkMonitor.pathUpdateHandler = { path in
            isNetworkAvailable = path.status == .satisfied
            
            if isNetworkAvailable {
                Task {
                    await uploadCachedFeedback()
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
        isMonitoringStarted = true
    }
    
    // MARK: - Public Methods
    
    /// Sends user feedback to Firebase Firestore with enhanced error handling
    /// - Parameters:
    ///   - text: The feedback text content
    ///   - type: The type of feedback (General, Bug Report, Feature, Question)
    ///   - email: Optional contact email
    ///   - includeDeviceInfo: Whether to include device information
    /// - Returns: FeedbackResult object with success status and error details if any
    static func sendFeedback(text: String, type: String, email: String, includeDeviceInfo: Bool) async throws -> FeedbackResult {
        // Start network monitoring if not already started
        if !isMonitoringStarted {
            startNetworkMonitoring()
        }
        
        // Input validation
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(error: .emptyFeedbackText)
        }
        
        // Email validation if provided
        if !email.isEmpty && !isValidEmail(email) {
            return .failure(error: .invalidEmail)
        }
        
        // Check rate limiting
        if isRateLimited() {
            return .failure(error: .rateLimitExceeded)
        }
        
        // Create the feedback document
        var feedbackData: [String: Any] = [
            "text": text,
            "type": type,
            "timestamp": FieldValue.serverTimestamp(),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
        
        // Add optional contact email if provided
        if !email.isEmpty {
            feedbackData["email"] = email
        }
        
        // Add device info if requested
        if includeDeviceInfo {
            await feedbackData["deviceInfo"] = [
                "device": UIDevice.current.model,
                "os": UIDevice.current.systemName,
                "osVersion": UIDevice.current.systemVersion,
                "buildVersion": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
                "idiom": UIDevice.current.userInterfaceIdiom.description,
                "screenSize": getScreenSize(),
                "locale": Locale.current.identifier
            ]
        }
        
        // Network connectivity check
        if !isNetworkAvailable {
            // Cache the feedback for later submission when online
            cacheFeedback(feedbackData)
            return .failure(error: .networkOffline)
        }
        
        // Send to Firestore with timeout
        do {
            // Use withTimeout to prevent hanging requests
            let documentReference = try await withTimeout(seconds: 15) {
                try await db.collection("feedback").addDocument(data: feedbackData)
            }
            
            // Track this submission for rate limiting
            trackSubmission()
            
            // Log analytics event if needed
            // Analytics.logEvent("feedback_submitted", parameters: ["type": type])
            
            return .success(documentID: documentReference.documentID)
        } catch {
            // Handle Firestore-specific errors
            if let nsError = error as NSError? {
                if nsError.domain == FirestoreErrorDomain {
                    switch nsError.code {
                    case FirestoreErrorCode.unavailable.rawValue:
                        // Store for later submission
                        cacheFeedback(feedbackData)
                        return .failure(error: .networkOffline)
                        
                    case FirestoreErrorCode.cancelled.rawValue,
                         FirestoreErrorCode.deadlineExceeded.rawValue:
                        return .failure(error: .timeout)
                        
                    case FirestoreErrorCode.permissionDenied.rawValue:
                        return .failure(error: .firebaseError("Permission denied"))
                        
                    default:
                        return .failure(error: .firebaseError(nsError.localizedDescription))
                    }
                }
            }
            
            // Generic error handling
            logError(error: error, data: feedbackData)
            return .failure(error: .unknownError(error))
        }
    }
    
    /// For testing purposes - get all feedback (in real app, this would be admin-only)
    static func getAllFeedback() async throws -> [Feedback] {
        if !isNetworkAvailable {
            throw FeedbackError.networkOffline
        }
        
        do {
            let snapshot = try await withTimeout(seconds: 10) {
                try await db.collection("feedback")
                    .order(by: "timestamp", descending: true)
                    .getDocuments()
            }
            
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
        } catch {
            if let nsError = error as NSError?, nsError.domain == FirestoreErrorDomain {
                throw FeedbackError.firebaseError(nsError.localizedDescription)
            } else {
                throw FeedbackError.unknownError(error)
            }
        }
    }
    
    /// Clear all cached feedback (e.g., for privacy purposes)
    static func clearCachedFeedback() {
        UserDefaults.standard.removeObject(forKey: cachedFeedbackKey)
    }
    
    // MARK: - Private Helper Methods
    
    /// Validate email format
    private static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    /// Timeout handler for async operations
    private static func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        // Create a task for the operation with a timeout
        return try await Task.detached {
            // Create a task for the actual operation
            let operationTask = Task {
                try await operation()
            }
            
            // Create a separate timeout task
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                // If we reach here, the timeout has occurred
                operationTask.cancel()
                throw TimeoutError()
            }
            
            do {
                // Wait for the operation to complete
                let result = try await operationTask.value
                // Operation completed successfully, cancel the timeout task
                timeoutTask.cancel()
                return result
            } catch is CancellationError {
                // Operation was cancelled, likely due to timeout
                throw TimeoutError()
            } catch {
                // Operation failed with some other error
                timeoutTask.cancel()
                throw error
            }
        }.value
    }
    
    /// Get device screen size for additional device info
    private static func getScreenSize() -> String {
        let screenBounds = UIScreen.main.bounds
        return "\(Int(screenBounds.width))x\(Int(screenBounds.height))"
    }
    
    /// Log errors to console (could be extended to send to a logging service)
    private static func logError(error: Error, data: [String: Any]? = nil) {
        #if DEBUG
        print("Feedback Error: \(error.localizedDescription)")
        if let data = data {
            print("Associated data: \(data)")
        }
        #endif
        
        // In a production app, you might want to log to a service like Firebase Crashlytics
        // Crashlytics.crashlytics().record(error: error)
    }
    
    // MARK: - Rate Limiting Methods
    
    /// Check if submissions are being rate limited
    private static func isRateLimited() -> Bool {
        let now = Date()
        
        // Remove submissions older than the rate limit window
        recentSubmissions = recentSubmissions.filter {
            now.timeIntervalSince($0) <= rateLimitWindow
        }
        
        // Check if we've hit the rate limit
        return recentSubmissions.count >= feedbackRateLimit
    }
    
    /// Track a new submission for rate limiting
    private static func trackSubmission() {
        recentSubmissions.append(Date())
    }
    
    // MARK: - Offline Caching Methods
    
    /// Cache feedback for later submission when online
    private static func cacheFeedback(_ feedbackData: [String: Any]) {
        let defaults = UserDefaults.standard
        
        // Get existing cached feedback
        var cachedFeedback = defaults.array(forKey: cachedFeedbackKey) as? [[String: Any]] ?? []
        
        // Add this feedback to the cache
        var feedbackCopy = feedbackData
        // Convert Firestore FieldValue to regular timestamp because it can't be serialized
        feedbackCopy["timestamp"] = Date().timeIntervalSince1970
        
        cachedFeedback.append(feedbackCopy)
        
        // Save back to UserDefaults
        defaults.set(cachedFeedback, forKey: cachedFeedbackKey)
    }
    
    /// Upload cached feedback when coming back online
    private static func uploadCachedFeedback() async {
        let defaults = UserDefaults.standard
        
        guard let cachedFeedback = defaults.array(forKey: cachedFeedbackKey) as? [[String: Any]],
              !cachedFeedback.isEmpty else {
            return
        }
        
        var remainingFeedback: [[String: Any]] = []
        
        for feedback in cachedFeedback {
            var feedbackCopy = feedback
            
            // Convert timestamp back to FieldValue
            if let timestamp = feedbackCopy["timestamp"] as? TimeInterval {
                feedbackCopy.removeValue(forKey: "timestamp")
                feedbackCopy["timestamp"] = FieldValue.serverTimestamp()
                feedbackCopy["cached"] = true
                feedbackCopy["originalTimestamp"] = timestamp
            }
            
            do {
                _ = try await db.collection("feedback").addDocument(data: feedbackCopy)
                
                // Track this submission for rate limiting
                trackSubmission()
            } catch {
                // If we couldn't upload this feedback, keep it for later
                remainingFeedback.append(feedback)
            }
        }
        
        // Update the cache with any feedback that couldn't be uploaded
        defaults.set(remainingFeedback, forKey: cachedFeedbackKey)
    }
}

// MARK: - Error Types

// Custom timeout error
private struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "The operation timed out"
    }
}

// MARK: - Extensions

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
