//
//  ContentView.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-10.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var auth = AuthState()

    var body: some View {
        Group {
                if auth.isLoggedIn {
                    HomeView()
                        .environmentObject(auth)
                } else {
                    LoginView()
                        .environmentObject(auth)
                }
            }
    }

}
