//
//  EventPlannerApp.swift
//  EventPlanner
//
//  Created by oscar villatoro on 24/11/26.
//

import SwiftUI
import FirebaseCore

@main
struct EventPlannerApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
