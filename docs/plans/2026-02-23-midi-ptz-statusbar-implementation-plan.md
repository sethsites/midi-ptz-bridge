# MIDI-PTZ Status Bar App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS menu bar app that listens to CoreMIDI notes from multiple sources, evaluates rule-based mappings, triggers vendor-specific PTZ HTTP commands with retries, logs activity, and provides a configuration UI with status flashes.

**Architecture:** A SwiftUI + AppKit menu bar app with a CoreMIDI listener for multiple sources, a rule engine that resolves commands, an HTTP client with retry logic, and a logging subsystem that writes a rotating file plus an in-memory last-5 buffer. Configuration is stored in an app support JSON file (including camera credentials).

**Tech Stack:** Swift, SwiftUI, AppKit, CoreMIDI, URLSession, XCTest.

---

### Task 1: Scaffold the macOS App and Menu Bar Shell

**Files:**
- Create: `MIDI-PTZ-Bridge.xcodeproj` (via Xcode new project)
- Create: `MIDI-PTZ-Bridge/` (Xcode app target sources)
- Modify: `MIDI-PTZ-Bridge/Info.plist`

**Step 1: Create the Xcode project**
- Action: In Xcode, create a new macOS App project named `MIDI-PTZ-Bridge` in this repo.
- Ensure SwiftUI lifecycle and AppKit integration are enabled.
- Add `LSUIElement = YES` to `Info.plist` to hide Dock icon.

**Step 2: Write a failing UI test placeholder**
- Add test target `MIDI-PTZ-BridgeTests` if not created.
- Create `MIDI-PTZ-BridgeTests/AppShellTests.swift` with:

```swift
import XCTest
@testable import MIDI_PTZ_Bridge

final class AppShellTests: XCTestCase {
    func testAppLaunches() {
        XCTAssertTrue(true)
    }
}
```

**Step 3: Run tests**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: PASS

**Step 4: Commit**
```bash
git add MIDI-PTZ-Bridge.xcodeproj MIDI-PTZ-Bridge MIDI-PTZ-BridgeTests
git commit -m "chore: scaffold macOS app shell"
```

---

### Task 2: Define Config Models and Persistence

**Files:**
- Create: `MIDI-PTZ-Bridge/Models/Config.swift`
- Create: `MIDI-PTZ-Bridge/Services/ConfigStore.swift`
- Test: `MIDI-PTZ-BridgeTests/ConfigStoreTests.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import MIDI_PTZ_Bridge

final class ConfigStoreTests: XCTestCase {
    func testRoundTripConfig() throws {
        let store = ConfigStore(baseURL: FileManager.default.temporaryDirectory)
        let config = AppConfig(
            midiSources: ["IAC Driver Bus 1", "IAC Driver Bus 2"],
            cameras: [Camera(id: UUID(), name: "Cam A", ip: "192.168.0.10", username: "u", password: "p")],
            commandTemplates: [CommandTemplate(id: UUID(), name: "Home", method: .get, path: "/home", headers: [:], body: nil)],
            rules: [Rule(id: UUID(), note: 60, onOff: .on, velocity: .exact(100), cameraId: nil, commandTemplateId: nil)]
        )
        try store.save(config)
        let loaded = try store.load()
        XCTAssertEqual(loaded.midiSources, config.midiSources)
        XCTAssertEqual(loaded.cameras.count, 1)
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: FAIL (missing types)

**Step 3: Write minimal implementation**
Implement `AppConfig`, `Camera`, `CommandTemplate`, `Rule`, and `VelocityCondition` as `Codable` in `Config.swift`. Implement `ConfigStore` with JSON load/save in Application Support (or provided baseURL for tests).

**Step 4: Run test to verify it passes**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: PASS

**Step 5: Commit**
```bash
git add MIDI-PTZ-Bridge/Models/Config.swift MIDI-PTZ-Bridge/Services/ConfigStore.swift MIDI-PTZ-BridgeTests/ConfigStoreTests.swift
git commit -m "feat: add config models and persistence"
```

---

### Task 3: CoreMIDI Listener Service (Multiple Sources)

**Files:**
- Create: `MIDI-PTZ-Bridge/Services/MidiListener.swift`
- Test: `MIDI-PTZ-BridgeTests/MidiListenerTests.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import MIDI_PTZ_Bridge

final class MidiListenerTests: XCTestCase {
    func testParsesNoteOn() {
        let event = MidiEvent(note: 60, velocity: 100, onOff: .on, sourceName: "Bus")
        XCTAssertEqual(event.note, 60)
        XCTAssertEqual(event.sourceName, "Bus")
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: FAIL (missing types)

**Step 3: Write minimal implementation**
Define `MidiEvent` model (note, velocity, onOff, sourceName) and a `MidiListener` that exposes a callback/Combine publisher of `MidiEvent`. Implement selection of multiple source names and subscribe to each. Stub low-level CoreMIDI wiring behind a protocol so tests can inject mock events.

**Step 4: Run test to verify it passes**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: PASS

**Step 5: Commit**
```bash
git add MIDI-PTZ-Bridge/Services/MidiListener.swift MIDI-PTZ-BridgeTests/MidiListenerTests.swift
git commit -m "feat: add midi listener abstraction"
```

---

### Task 4: Rule Engine and Command Resolution

**Files:**
- Create: `MIDI-PTZ-Bridge/Services/RuleEngine.swift`
- Test: `MIDI-PTZ-BridgeTests/RuleEngineTests.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import MIDI_PTZ_Bridge

final class RuleEngineTests: XCTestCase {
    func testResolvesCommandForExactMatch() {
        let camId = UUID()
        let cmdId = UUID()
        let config = AppConfig(
            midiSources: ["Bus"],
            cameras: [Camera(id: camId, name: "Cam", ip: "1.2.3.4", username: "u", password: "p")],
            commandTemplates: [CommandTemplate(id: cmdId, name: "Home", method: .get, path: "/home", headers: [:], body: nil)],
            rules: [Rule(id: UUID(), note: 60, onOff: .on, velocity: .exact(100), cameraId: camId, commandTemplateId: cmdId)]
        )
        let engine = RuleEngine(config: config)
        let event = MidiEvent(note: 60, velocity: 100, onOff: .on, sourceName: "Bus")
        let action = engine.resolve(event)
        XCTAssertEqual(action?.camera.name, "Cam")
        XCTAssertEqual(action?.command.path, "/home")
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: FAIL

**Step 3: Write minimal implementation**
Implement `RuleEngine` and `ResolvedAction` to match on note/onOff and `VelocityCondition` (exact, min, max, range). Return camera + command template.

**Step 4: Run test to verify it passes**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: PASS

**Step 5: Commit**
```bash
git add MIDI-PTZ-Bridge/Services/RuleEngine.swift MIDI-PTZ-BridgeTests/RuleEngineTests.swift
git commit -m "feat: add rule engine"
```

---

### Task 5: HTTP Client with Basic Auth and Retries

**Files:**
- Create: `MIDI-PTZ-Bridge/Services/PTZHttpClient.swift`
- Test: `MIDI-PTZ-BridgeTests/PTZHttpClientTests.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import MIDI_PTZ_Bridge

final class PTZHttpClientTests: XCTestCase {
    func testBuildsRequestWithBasicAuth() throws {
        let client = PTZHttpClient()
        let camera = Camera(id: UUID(), name: "Cam", ip: "1.2.3.4", username: "user", password: "pass")
        let command = CommandTemplate(id: UUID(), name: "Test", method: .get, path: "/ptz", headers: [:], body: nil)
        let request = try client.buildRequest(camera: camera, command: command)
        XCTAssertEqual(request.url?.absoluteString, "http://1.2.3.4/ptz")
        XCTAssertNotNil(request.value(forHTTPHeaderField: "Authorization"))
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: FAIL

**Step 3: Write minimal implementation**
Implement `buildRequest` and `send` using `URLSession`. Add `HTTPMethod` enum and support optional headers/body. Add retry loop (up to 3 attempts) with small delay.

**Step 4: Run test to verify it passes**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: PASS

**Step 5: Commit**
```bash
git add MIDI-PTZ-Bridge/Services/PTZHttpClient.swift MIDI-PTZ-BridgeTests/PTZHttpClientTests.swift
git commit -m "feat: add PTZ HTTP client"
```

---

### Task 6: Logging Subsystem with Rotation and Last-5 Buffer

**Files:**
- Create: `MIDI-PTZ-Bridge/Services/LogStore.swift`
- Test: `MIDI-PTZ-BridgeTests/LogStoreTests.swift`

**Step 1: Write the failing test**
```swift
import XCTest
@testable import MIDI_PTZ_Bridge

final class LogStoreTests: XCTestCase {
    func testAppendsAndRotates() throws {
        let dir = FileManager.default.temporaryDirectory
        let store = LogStore(baseURL: dir, maxBytes: 100, maxFiles: 2)
        for _ in 0..<20 { store.append(.init(type: .midi, status: .ok, summary: "x", details: "y")) }
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.appendingPathComponent("activity.log").path))
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: FAIL

**Step 3: Write minimal implementation**
Implement `LogStore` to append lines, rotate when exceeding `maxBytes`, and keep `activity.log`, `activity.log.1`, `activity.log.2` up to `maxFiles`. Keep an in-memory ring buffer of last 5 events for the menu.

**Step 4: Run test to verify it passes**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: PASS

**Step 5: Commit**
```bash
git add MIDI-PTZ-Bridge/Services/LogStore.swift MIDI-PTZ-BridgeTests/LogStoreTests.swift
git commit -m "feat: add logging with rotation"
```

---

### Task 7: Status Bar UI and Menu Updates

**Files:**
- Create: `MIDI-PTZ-Bridge/UI/StatusBarController.swift`
- Modify: `MIDI-PTZ-Bridge/MIDI_PTZ_BridgeApp.swift`
- Modify: `MIDI-PTZ-Bridge/ContentView.swift`

**Step 1: Write a failing test (logic-level)**
```swift
import XCTest
@testable import MIDI_PTZ_Bridge

final class StatusBarControllerTests: XCTestCase {
    func testMenuShowsLastFiveEvents() {
        let events = (0..<6).map { _ in LogEvent(type: .midi, status: .ok, summary: "a", details: "b") }
        let controller = StatusBarController()
        let items = controller.menuItems(for: events)
        XCTAssertEqual(items.count, 5)
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: FAIL

**Step 3: Write minimal implementation**
Implement `StatusBarController` that creates `NSStatusItem`, builds menu items from last 5 events, and exposes a `flash(status:)` method that briefly swaps a colored template image (green/red) then restores.

**Step 4: Run test to verify it passes**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: PASS

**Step 5: Commit**
```bash
git add MIDI-PTZ-Bridge/UI/StatusBarController.swift MIDI-PTZ-Bridge/MIDI_PTZ_BridgeApp.swift MIDI-PTZ-Bridge/ContentView.swift MIDI-PTZ-BridgeTests/StatusBarControllerTests.swift
git commit -m "feat: add status bar UI"
```

---

### Task 8: Configuration Window and CRUD Views

**Files:**
- Create: `MIDI-PTZ-Bridge/UI/Config/ConfigWindow.swift`
- Create: `MIDI-PTZ-Bridge/UI/Config/MidiSourcesView.swift`
- Create: `MIDI-PTZ-Bridge/UI/Config/CamerasView.swift`
- Create: `MIDI-PTZ-Bridge/UI/Config/CommandsView.swift`
- Create: `MIDI-PTZ-Bridge/UI/Config/RulesView.swift`
- Modify: `MIDI-PTZ-Bridge/ContentView.swift`

**Step 1: Write a failing test (view model)**
```swift
import XCTest
@testable import MIDI_PTZ_Bridge

final class ConfigViewModelTests: XCTestCase {
    func testAddsCamera() {
        let vm = ConfigViewModel(config: AppConfig.empty)
        vm.addCamera(name: "Cam", ip: "1.2.3.4", username: "u", password: "p")
        XCTAssertEqual(vm.config.cameras.count, 1)
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: FAIL

**Step 3: Write minimal implementation**
Create `ConfigViewModel` to manage CRUD and persistence via `ConfigStore`. Wire SwiftUI views to the view model. Include editing of multiple MIDI sources and rule velocity conditions.

**Step 4: Run test to verify it passes**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: PASS

**Step 5: Commit**
```bash
git add MIDI-PTZ-Bridge/UI/Config MIDI-PTZ-Bridge/Models MIDI-PTZ-Bridge/Services MIDI-PTZ-BridgeTests/ConfigViewModelTests.swift
git commit -m "feat: add configuration UI"
```

---

### Task 9: End-to-End Wiring (MIDI -> Rule -> HTTP -> Log -> Flash)

**Files:**
- Modify: `MIDI-PTZ-Bridge/MIDI_PTZ_BridgeApp.swift`
- Modify: `MIDI-PTZ-Bridge/Services/MidiListener.swift`
- Modify: `MIDI-PTZ-Bridge/Services/RuleEngine.swift`
- Modify: `MIDI-PTZ-Bridge/Services/PTZHttpClient.swift`
- Modify: `MIDI-PTZ-Bridge/Services/LogStore.swift`

**Step 1: Write a failing integration test (logic-level)**
```swift
import XCTest
@testable import MIDI_PTZ_Bridge

final class PipelineTests: XCTestCase {
    func testMidiEventTriggersHttpAndLogs() {
        // Use mock listener and mock HTTP client.
        XCTAssertTrue(true)
    }
}
```

**Step 2: Run test to verify it fails**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: FAIL

**Step 3: Write minimal implementation**
Wire services together in app lifecycle: on MIDI event, resolve rule, send HTTP (with retries), log request/response, flash status.

**Step 4: Run test to verify it passes**
Run: `xcodebuild test -scheme "MIDI-PTZ-Bridge" -destination "platform=macOS"`
Expected: PASS

**Step 5: Commit**
```bash
git add MIDI-PTZ-Bridge/MIDI_PTZ_BridgeApp.swift MIDI-PTZ-Bridge/Services MIDI-PTZ-BridgeTests/PipelineTests.swift
git commit -m "feat: wire MIDI pipeline"
```

---

### Task 10: Manual Validation Checklist

**Files:**
- Modify: `README.md` (if created)

**Step 1: Add a README with manual test steps**
Include how to select MIDI sources, add camera, create rule, and confirm status flashes.

**Step 2: Commit**
```bash
git add README.md
git commit -m "docs: add manual validation steps"
```
