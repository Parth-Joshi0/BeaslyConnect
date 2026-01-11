//
//  HomeView.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-10.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthState

    var body: some View {
        NavigationStack {

            VStack(spacing: 12) {
                
                Spacer()
                
                Text("Welcome to Neighbour Link")
                    .font(.system(size: 44, weight: .regular))
                
                Text("Choose your role to continue")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
                
                Spacer()
                                
                VStack() {
                    NavigationLink(destination: VolunteerView().navigationBarBackButtonHidden(true)) {
                        HStack {
                            Text("Volunteer")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "figure.walk")  // placeholder icon
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    NavigationLink(destination: UserView().navigationBarBackButtonHidden(true)) {
                        HStack {
                            Text("User")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "person.fill")
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .buttonBorderShape(.roundedRectangle(radius: 15))
                    .padding(.horizontal)
                    .tint(Color.black)
                    
                }
            }
            .padding(.bottom, 95)
        }
        .padding()
    }
}
