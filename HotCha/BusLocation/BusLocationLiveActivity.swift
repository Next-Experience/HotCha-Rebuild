//
//  BusLocationLiveActivity.swift
//  BusLocation
//
//  Created by 문호 on 4/9/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BusLocationAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BusLocationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BusLocationAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension BusLocationAttributes {
    fileprivate static var preview: BusLocationAttributes {
        BusLocationAttributes(name: "World")
    }
}

extension BusLocationAttributes.ContentState {
    fileprivate static var smiley: BusLocationAttributes.ContentState {
        BusLocationAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BusLocationAttributes.ContentState {
         BusLocationAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BusLocationAttributes.preview) {
   BusLocationLiveActivity()
} contentStates: {
    BusLocationAttributes.ContentState.smiley
    BusLocationAttributes.ContentState.starEyes
}
