//
//  beastlyConnectApp.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-10.
//

import SwiftUI
import SwiftData

@main
struct beastlyConnectApp: App {
    @StateObject private var auth = AuthState()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(auth)
        }
    }
}
