//
//  AuthenticationView.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // App Logo/Title
                    VStack(spacing: 16) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("EyesOn")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Report suspicious activities in your community")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Quick Anonymous Sign In
                    VStack(spacing: 16) {
                        Button(action: {
                            Task { await viewModel.signInAnonymously() }
                        }) {
                            HStack {
                                Image(systemName: "person.circle")
                                Text("Continue Anonymously")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(viewModel.isLoading)
                        
                        Text("or")
                            .foregroundColor(.secondary)
                    }
                    
                    // Email/Password Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                        
                        Button(action: {
                            Task { await viewModel.signInWithEmail() }
                        }) {
                            Text(viewModel.isSignUp ? "Sign Up" : "Sign In")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(viewModel.isLoading)
                        
                        Button(action: viewModel.toggleSignUpMode) {
                            Text(viewModel.isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarHidden(true)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
}
