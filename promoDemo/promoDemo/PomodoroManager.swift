//
//  PomodoroManager.swift
//  promoDemo
//
//  Created by Esteban  Martinez Mota on 3/19/26.
//

import Foundation
import ActivityKit
import Combine

class PomodoroManager: ObservableObject {
    //Step 9
    @Published var totalRounds: Int = 4
    @Published var currentRound: Int = 1

    @Published var focusTime: Int = 1500
    @Published var breakTime: Int = 300
    @Published var remainingTime: Int = 1500

    @Published var phase: String = "Focus"

    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false

    var timer: Timer?

    var activity: Activity<PomodoroAttributes>?

    //Step 10
    func startPomodoro() {

        currentRound = 1
        phase = "Focus"
        remainingTime = focusTime

        isRunning = true
        isPaused = false

        startLiveActivity()
        startTimer()
    }

    //Step 11
    func pausePomodoro() {

        isPaused = true
        timer?.invalidate()
    }

    //Step 12
    func resumePomodoro() {

        isPaused = false
        startTimer()
    }

    //Step 13
    func endPomodoro() {

        timer?.invalidate()

        isRunning = false
        isPaused = false

        currentRound = 1
        phase = "Focus"
        remainingTime = focusTime

        endLiveActivity()
    }

    //Step14
    func startTimer() {

        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.remainingTime > 0 {
                self.remainingTime -= 1
                self.updateLiveActivity()
            } else {
                self.switchPhase()
                self.updateLiveActivity()
            }
        }
    }

    //Step 15
    func switchPhase() {

        if phase == "Focus" {
            phase = "Break"
            remainingTime = breakTime
        } else {
            if currentRound < totalRounds {
                currentRound += 1
                phase = "Focus"
                remainingTime = focusTime
            } else {
                endPomodoro()
            }
        }
    }

    //Step 16
    func startLiveActivity() {

        print("Activities enabled: \(ActivityAuthorizationInfo().areActivitiesEnabled)")

        if !ActivityAuthorizationInfo().areActivitiesEnabled {
            print("Live Activities are disabled on this device")
            return
        }

        let attributes = PomodoroAttributes(totalRounds: totalRounds)

        let contentState = PomodoroAttributes.ContentState(
            phase: phase,
            round: currentRound,
            remainingTime: remainingTime
        )

        let content = ActivityContent(
            state: contentState,
            staleDate: nil
        )

        do {
            activity = try Activity<PomodoroAttributes>.request(
                attributes: attributes,
                content: content
            )
            print("Live Activity started")
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }

    //Step 17
    func updateLiveActivity() {

        guard let activity = activity else { return }

        let contentState = PomodoroAttributes.ContentState(
            phase: phase,
            round: currentRound,
            remainingTime: remainingTime
        )

        let content = ActivityContent(
            state: contentState,
            staleDate: nil
        )

        Task {
            await activity.update(content)
        }
    }

    //Step 18
    func endLiveActivity() {

        guard let activity = activity else { return }

        let contentState = PomodoroAttributes.ContentState(
            phase: phase,
            round: currentRound,
            remainingTime: remainingTime
        )

        let content = ActivityContent(
            state: contentState,
            staleDate: nil
        )

        Task {
            await activity.end(content, dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
}
