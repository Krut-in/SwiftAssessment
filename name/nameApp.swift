//
//  nameApp.swift
//  name
//
//  Created by Krutin Rathod on 21/11/25.
//
//  DESCRIPTION:
//  Main application entry point for the Luna venue discovery iOS app.
//  This file defines the SwiftUI App structure and initializes the root view.
//  
//  ARCHITECTURE:
//  - Uses SwiftUI's @main attribute to mark the app entry point
//  - ContentView serves as the root view containing tab navigation
//  - AppState is initialized as a singleton for global state management
//

import SwiftUI

@main
struct nameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
