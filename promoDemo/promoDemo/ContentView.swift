//
//  ContentView.swift
//  promoDemo
//
//  Created by Esteban  Martinez Mota on 3/19/26.
//

//step 19
import SwiftUI

struct ContentView: View {
    @StateObject private var pomodoroManager = PomodoroManager()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.indigo.opacity(0.9), Color.blue.opacity(0.8), Color.cyan.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    timerCard
                    controlsCard
                    settingsCard
                }
                .padding(16)
            }
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Focus Session", systemImage: "timer")
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                Spacer()

                statusPill
            }

            Text("Round \(pomodoroManager.currentRound) of \(pomodoroManager.totalRounds)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var timerCard: some View {
        VStack(spacing: 14) {
            Text(pomodoroManager.phase)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.95))

            Text(timeString(from: pomodoroManager.remainingTime))
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            ProgressView(value: progressValue)
                .tint(.white)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            HStack(spacing: 10) {
                miniStat(title: "Focus", value: "\(pomodoroManager.focusTime / 60)m")
                miniStat(title: "Break", value: "\(pomodoroManager.breakTime / 60)m")
                miniStat(title: "Rounds", value: "\(pomodoroManager.totalRounds)")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }

    private var controlsCard: some View {
        VStack(spacing: 12) {
            Button {
                pomodoroManager.startPomodoro()
            } label: {
                Label("Start Session", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(color: .green))

            HStack(spacing: 12) {
                Button {
                    if pomodoroManager.isPaused {
                        pomodoroManager.resumePomodoro()
                    } else {
                        pomodoroManager.pausePomodoro()
                    }
                } label: {
                    Label(pomodoroManager.isPaused ? "Resume" : "Pause",
                          systemImage: pomodoroManager.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(color: .orange))

                Button {
                    pomodoroManager.endPomodoro()
                } label: {
                    Label("End", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(color: .red))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Settings")
                .font(.headline)
                .foregroundStyle(.white)

            Stepper("Rounds: \(pomodoroManager.totalRounds)",
                    value: $pomodoroManager.totalRounds, in: 1...10)
                .foregroundStyle(.white)

            Stepper("Focus Time: \(pomodoroManager.focusTime / 60) min",
                    value: $pomodoroManager.focusTime, in: 60...3600, step: 60)
                .foregroundStyle(.white)

            Stepper("Break Time: \(pomodoroManager.breakTime / 60) min",
                    value: $pomodoroManager.breakTime, in: 60...1800, step: 60)
                .foregroundStyle(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var statusPill: some View {
        Text(
            !pomodoroManager.isRunning ? "Idle" :
            pomodoroManager.isPaused ? "Paused" : "Running"
        )
        .font(.caption.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.white.opacity(0.18))
        )
        .foregroundStyle(.white)
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var progressValue: Double {
        let total = pomodoroManager.phase == "Focus" ? pomodoroManager.focusTime : pomodoroManager.breakTime
        guard total > 0 else { return 0 }
        return 1 - (Double(pomodoroManager.remainingTime) / Double(total))
    }

    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Button Style

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(configuration.isPressed ? 0.7 : 0.9))
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
