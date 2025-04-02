import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Attributes

/// Attributes for Moti quote live activities
struct MotiWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about the activity
        var quote: String
        var author: String
        var timePassed: TimeInterval
    }

    // Fixed non-changing properties about the activity
    var category: String
    var startTime: Date
}

// MARK: - Live Activity Widget Implementation

/// Live Activity Widget for displaying active quotes during focused sessions
struct MotiWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MotiWidgetAttributes.self) { context in
            // Lock screen/banner UI
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.05, green: 0.05, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 12) {
                    // Session status indicator
                    HStack {
                        Label {
                            Text("Motivation Session")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        } icon: {
                            Image(systemName: "quote.bubble.fill")
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Show elapsed time
                        Label {
                            Text(formatTime(context.state.timePassed))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "timer")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quote content
                    VStack(spacing: 8) {
                        Text(context.state.quote)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .padding(.horizontal)
                        
                        Text("— \(context.state.author)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 8)
                    
                    // Category chip
                    Text(context.attributes.category)
                        .font(.caption2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
                .padding(.vertical, 16)
            }
            .activityBackgroundTint(Color(red: 0.1, green: 0.1, blue: 0.3))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI for Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.category)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    } icon: {
                        Image(systemName: getCategoryIcon(context.attributes.category))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .font(.caption)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        // Format time passed
                        Text(formatTime(context.state.timePassed))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(.white.opacity(0.7))
                    } icon: {
                        Image(systemName: "timer")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .font(.caption)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Quote content in expanded view
                    VStack(alignment: .center, spacing: 4) {
                        Text(context.state.quote)
                            .font(.callout)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                        
                        Text("— \(context.state.author)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                // Leading part of compact view
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(.white)
                    .font(.caption2)
            } compactTrailing: {
                // Trailing part of compact view
                Text(formatTime(context.state.timePassed))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundColor(.white)
            } minimal: {
                // Minimal view (just icon)
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(.white)
            }
            .widgetURL(URL(string: "moti://quotes"))
            .keylineTint(Color.cyan)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Format time interval to mm:ss
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Get icon for a category
    private func getCategoryIcon(_ category: String) -> String {
        switch category {
        case "Success & Achievement": return "trophy"
        case "Life & Perspective": return "scope"
        case "Dreams & Goals": return "sparkles"
        case "Courage & Confidence": return "bolt.heart"
        case "Perseverance & Resilience": return "figure.walk"
        case "Growth & Change": return "leaf"
        case "Action & Determination": return "flag"
        case "Mindset & Attitude": return "brain"
        case "Focus & Discipline": return "target"
        default: return "quote.bubble"
        }
    }
}

// MARK: - Previews

#Preview("Live Activity", as: .content) {
    MotiWidgetLiveActivity()
} contentState: {
    MotiWidgetAttributes.ContentState(
        quote: "Whether you think you can or you think you can't, you're right.",
        author: "Henry Ford",
        timePassed: 325
    )
}

extension MotiWidgetAttributes {
    static var preview: MotiWidgetAttributes {
        MotiWidgetAttributes(
            category: "Mindset & Attitude",
            startTime: Date()
        )
    }
}

extension MotiWidgetAttributes.ContentState {
    static var initial: MotiWidgetAttributes.ContentState {
        MotiWidgetAttributes.ContentState(
            quote: "The way to get started is to quit talking and begin doing.",
            author: "Walt Disney",
            timePassed: 0
        )
    }
     
    static var updated: MotiWidgetAttributes.ContentState {
        MotiWidgetAttributes.ContentState(
            quote: "It always seems impossible until it's done.",
            author: "Nelson Mandela",
            timePassed: 180
        )
    }
}
