# Pomodoro Live Activity Documentation - Repeatable Setup Guide

## Goal

Build a **SwiftUI Pomodoro app** with:

- Main app UI
- Widget Extension
- Lock Screen Live Activity
- Dynamic Island support

Important fix:  
Edit the **actual `Info.plist` files**, not only the target Info tab UI.

---

# Requirements

- Xcode
- iPhone running **iOS 16.1+**
- Real device for Live Activity testing
- SwiftUI iOS project

---

# Step 1) Create the base SwiftUI app

1. Open **Xcode**
2. Navigate to:

```

File > New > Project

```

3. Select:

```

App

```

4. Set:

- Interface: `SwiftUI`
- Language: `Swift`

5. Create the project.
6. Run the base app once to confirm it builds.

---

# Step 2) Add the Widget Extension target

1. Open your project in **Xcode**
2. Navigate to:

```

File > New > Target...

```

3. Search for:

```

Widget Extension

```

4. Select **Widget Extension**
5. Click **Next**

Set:

```

Product Name: PomodoroWidgetExtension
Language: Swift

```

6. Make sure:

```

Include Live Activity

```

is **checked**

7. If this appears:

```

Include Configuration App Intent

```

and it is optional for your setup, **uncheck it**

8. Click **Finish**

9. If Xcode asks:

```

Activate scheme?

```

choose:

```

Activate

````

10. Confirm the project now has:

- Main app target
- Widget extension target

---

# Step 3) Enable Live Activities correctly

Edit the **actual plist files**, not just the UI.

Add this key to **both**:

- Main app `Info.plist`
- Widget extension `Info.plist`

```xml
<key>NSSupportsLiveActivities</key>
<true/>
````

Also check project settings:

1. Select the **project**
2. Select the **main app target**
3. Open **Signing & Capabilities**
4. Click **+ Capability**
5. Add:

```
Background Modes
```

Enable:

* Background fetch
* Remote notifications

Ensure deployment target is:

```
iOS 16.1+
```

---

# Step 4) Create `PomodoroAttributes.swift`

Create a new Swift file in the **main app target**:

```
PomodoroAttributes.swift
```

Add:

```swift
import ActivityKit

struct PomodoroAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        var phase: String
        var round: Int
        var remainingTime: Int
    }

    var totalRounds: Int
}
```

### Target membership

This file must be included in:

* Main app target
* Widget extension target

### Purpose

Fixed data:

```
totalRounds
```

Dynamic activity state:

```
phase
round
remainingTime
```

---

# Step 5) Create `PomodoroManager.swift`

Create a Swift file in the **main app target**:

```
PomodoroManager.swift
```

Add:

```swift
import Foundation
import ActivityKit
import Combine

class PomodoroManager: ObservableObject {

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

    func startPomodoro() {

        currentRound = 1
        phase = "Focus"
        remainingTime = focusTime

        isRunning = true
        isPaused = false

        startLiveActivity()
        startTimer()
    }

    func pausePomodoro() {

        isPaused = true
        timer?.invalidate()
    }

    func resumePomodoro() {

        isPaused = false
        startTimer()
    }

    func endPomodoro() {

        timer?.invalidate()

        isRunning = false
        isPaused = false

        currentRound = 1
        phase = "Focus"
        remainingTime = focusTime

        endLiveActivity()
    }

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
```

### Responsibilities

This file manages:

* Pomodoro state
* Countdown timer
* Phase switching
* Live Activity lifecycle

---

# Step 6) Update `ContentView.swift`

Replace the file with:

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var pomodoroManager = PomodoroManager()

    var body: some View {
        VStack(spacing: 20) {

            Stepper("Rounds: \(pomodoroManager.totalRounds)",
                    value: $pomodoroManager.totalRounds,
                    in: 1...10)

            Stepper("Focus Time: \(pomodoroManager.focusTime / 60) min",
                    value: $pomodoroManager.focusTime,
                    in: 60...3600,
                    step: 60)

            Stepper("Break Time: \(pomodoroManager.breakTime / 60) min",
                    value: $pomodoroManager.breakTime,
                    in: 60...1800,
                    step: 60)

            Text("Phase: \(pomodoroManager.phase)")

            Text("Round: \(pomodoroManager.currentRound) / \(pomodoroManager.totalRounds)")

            Text("\(pomodoroManager.remainingTime / 60):\(String(format: "%02d", pomodoroManager.remainingTime % 60))")
                .font(.largeTitle)

            Button("Start") {
                pomodoroManager.startPomodoro()
            }

            Button(pomodoroManager.isPaused ? "Resume" : "Pause") {
                if pomodoroManager.isPaused {
                    pomodoroManager.resumePomodoro()
                } else {
                    pomodoroManager.pausePomodoro()
                }
            }

            Button("End") {
                pomodoroManager.endPomodoro()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
```

---

# Step 7) Create `PomodoroLiveActivity.swift`

Inside the **widget extension target**, create:

```
PomodoroLiveActivity.swift
```

Add:

```swift
import ActivityKit
import WidgetKit
import SwiftUI

struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroAttributes.self) { context in
            VStack(spacing: 12) {
                Text("Pomodoro")
                    .font(.headline)

                Text(context.state.phase)
                    .font(.title2)

                Text("Round \(context.state.round) of \(context.attributes.totalRounds)")

                Text("\(context.state.remainingTime / 60):\(String(format: "%02d", context.state.remainingTime % 60))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {

                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.phase)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("R\(context.state.round)/\(context.attributes.totalRounds)")
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.state.remainingTime / 60):\(String(format: "%02d", context.state.remainingTime % 60))")
                        .font(.title2)
                }

            } compactLeading: {
                Text(context.state.phase.prefix(1))
            } compactTrailing: {
                Text("\(context.state.remainingTime / 60)m")
            } minimal: {
                Text("P")
            }
        }
    }
}
```

### Target membership

This file should belong **only to the widget extension target**.

---

# Step 8) Update the Widget Bundle

Open:

```
PomodoroWidgetExtensionBundle.swift
```

Use:

```swift
import WidgetKit
import SwiftUI

@main
struct PomodoroWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        PomodoroLiveActivity()
    }
}
```

---

# Step 9) Build and Clean

After setup:

1. Build the project
2. If errors occur:

```
Product > Clean Build Folder
```

3. Delete the app from the device
4. Re-run the main app target

---

# Step 10) Test on a Real Device

1. Run the **main app target**
2. Press **Start**
3. Lock the phone
4. Check the **Lock Screen**
5. If supported, check the **Dynamic Island**

Expected behavior:

* Live Activity appears
* Timer counts down
* Focus → Break phase transitions
* Rounds update
* Pause stops timer
* Resume restarts timer
* End removes the activity

---

# Common Mistakes

1. Adding `NSSupportsLiveActivities` only in the UI and not in the actual plist file
2. Forgetting to include `PomodoroAttributes.swift` in both targets
3. Putting `PomodoroLiveActivity.swift` in the main app target
4. Running the widget scheme instead of the main app scheme
5. Testing only on simulator
6. Not enabling `Include Live Activity`
7. Deployment target below `iOS 16.1`
8. Old build artifacts causing errors

---

# Quick Repeat Checklist

* Create SwiftUI iOS app
* Run base app once
* Add Widget Extension
* Check **Include Live Activity**
* Add `NSSupportsLiveActivities` to both plist files
* Add **Background Modes** capability
* Create `PomodoroAttributes.swift`
* Share `PomodoroAttributes.swift` with both targets
* Create `PomodoroManager.swift`
* Update `ContentView.swift`
* Create `PomodoroLiveActivity.swift` in widget extension
* Update `PomodoroWidgetExtensionBundle.swift`
* Clean build folder
* Run main app on real device
* Start session and verify Lock Screen / Dynamic Island

---

# Minimal File Map

### Main App Target

```
ContentView.swift
PomodoroManager.swift
PomodoroAttributes.swift
```

### Widget Extension Target

```
PomodoroLiveActivity.swift
PomodoroWidgetExtensionBundle.swift
PomodoroAttributes.swift
```
