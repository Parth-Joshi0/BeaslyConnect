//
//  LoginView.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-10.
//

import SwiftUI
import Combine

struct LoginView: View {
    @EnvironmentObject var auth: AuthState

    @State private var isCreateAccount = true
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {

            Spacer().frame(height: 40)

            Text("Welcome")
                .font(.system(size: 44, weight: .regular))

            Text(isCreateAccount ? "Create your account to\ncontinue" : "Sign in to\ncontinue")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            Spacer().frame(height: 10)

            // Email
            VStack(alignment: .leading, spacing: 10) {
                Text("Email")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.85))

                TextField("Enter your email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 18)
                    .frame(height: 62)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color.gray.opacity(0.25), lineWidth: 1)
                    )
            }

            // Password
            VStack(alignment: .leading, spacing: 10) {
                Text("Password")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.85))

                HStack(spacing: 10) {
                    Group {
                        if showPassword {
                            TextField("Enter your password", text: $password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Enter your password", text: $password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 18)
                .frame(height: 62)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.gray.opacity(0.25), lineWidth: 1)
                )
            }

            Spacer().frame(height: 10)

            // Big button
            Button {
                // Fake: ignore credentials for now
                auth.logIn(email: email)
            } label: {
                Text(isCreateAccount ? "Create Account" : "Sign In")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
            .padding(.top, 6)

            Spacer().frame(height: 6)

            // Bottom link row
            HStack(spacing: 6) {
                Text(isCreateAccount ? "Already have an account?" : "Don’t have an account?")
                    .foregroundStyle(.secondary)

                Button {
                    isCreateAccount.toggle()
                } label: {
                    Text(isCreateAccount ? "Sign in" : "Create one")
                        .fontWeight(.semibold)
                }
            }
            .font(.system(size: 17))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 6)

            Spacer()
        }
        .padding(.horizontal, 28)
        .background(Color.white)
    }
}
