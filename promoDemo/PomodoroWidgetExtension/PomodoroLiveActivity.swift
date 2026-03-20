//
//  PomodoroLiveActivity.swift
//  promoDemo
//
//  Created by Esteban  Martinez Mota on 3/19/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroAttributes.self) { context in
            // Lock Screen / Banner
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Pomodoro", systemImage: "timer")
                        .font(.headline)

                    Spacer()

                    Text(context.state.phase.uppercased())
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                }

                Text(timeString(from: context.state.remainingTime))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()

                HStack {
                    Text("Round \(context.state.round)/\(context.attributes.totalRounds)")
                        .font(.subheadline)
                        .opacity(0.95)

                    Spacer()

                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                }
            }
            .padding(16)
            .activityBackgroundTint(Color.indigo.opacity(0.9))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.phase)
                        .font(.subheadline.weight(.semibold))
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("R\(context.state.round)/\(context.attributes.totalRounds)")
                        .font(.subheadline.monospacedDigit())
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "timer")
                        Text(timeString(from: context.state.remainingTime))
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                    }
                }
            } compactLeading: {
                Text(context.state.phase.prefix(1))
                    .font(.caption2.bold())
            } compactTrailing: {
                Text(shortTime(context.state.remainingTime))
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "timer")
            }
            .keylineTint(.cyan)
        }
    }

    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func shortTime(_ seconds: Int) -> String {
        let m = seconds / 60
        return "\(m)m"
    }
}
