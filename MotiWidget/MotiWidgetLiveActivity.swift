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
            VStack(spacing: 12) {
                // Session status indicator
                HStack {
                    Label {
                        Text("Motivation Session")
                            .font(.caption)
                    } icon: {
                        Image(systemName: "quote.bubble.fill")
                    }
                    
                    Spacer()
                    
                    // Show elapsed time
                    Label {
                        Text(formatTime(context.state.timePassed))
                            .font(.caption)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "timer")
                    }
                }
                .padding(.horizontal)
                
                // Quote content - simplified to match our minimal design
                Text(context.state.quote)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal)
            }
            .padding(.vertical, 16)
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI for Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.category)
                            .font(.caption2)
                    } icon: {
                        Image(systemName: getCategoryIcon(context.attributes.category))
                    }
                    .font(.caption)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        // Format time passed
                        Text(formatTime(context.state.timePassed))
                            .font(.caption)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "timer")
                    }
                    .font(.caption)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Quote content in expanded view - simplified to match our minimal design
                    Text(context.state.quote)
                        .font(.callout)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                }
            } compactLeading: {
                // Leading part of compact view
                Image(systemName: "quote.bubble.fill")
            } compactTrailing: {
                // Trailing part of compact view
                Text(formatTime(context.state.timePassed))
                    .font(.caption2)
                    .monospacedDigit()
            } minimal: {
                // Minimal view (just icon)
                Image(systemName: "quote.bubble.fill")
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

// MARK: - Helper Types for Testing

extension MotiWidgetAttributes {
    static var sample: MotiWidgetAttributes {
        MotiWidgetAttributes(
            category: "Mindset & Attitude",
            startTime: Date()
        )
    }
}

extension MotiWidgetAttributes.ContentState {
    static var sample: MotiWidgetAttributes.ContentState {
        MotiWidgetAttributes.ContentState(
            quote: "Whether you think you can or you think you can't, you're right.",
            author: "Henry Ford",
            timePassed: 325
        )
    }
}
