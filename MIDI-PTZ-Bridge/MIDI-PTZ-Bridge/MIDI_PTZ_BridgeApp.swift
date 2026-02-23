//
//  MIDI_PTZ_BridgeApp.swift
//  MIDI-PTZ-Bridge
//
//  Created by Seth Sites on 2/23/26.
//

import SwiftUI
import CoreData

@main
struct MIDI_PTZ_BridgeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
