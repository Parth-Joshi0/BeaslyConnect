//
//  AuthState.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-10.
//

import Foundation
import Combine

class AuthState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var email: String = ""
    
    func logIn(email: String) {
        self.email = email
        self.isLoggedIn = true
    }
    
    func logOut() {
        self.email = ""
        self.isLoggedIn = false
    }
}
