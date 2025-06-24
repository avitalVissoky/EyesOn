//
//  AuthenticationViewModel.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import Foundation
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSignUp = false
    
    private let firebaseService = FirebaseService.shared
    
    func signInAnonymously() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.signInAnonymously()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signInWithEmail() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                try await firebaseService.signUpWithEmail(email, password: password)
            } else {
                try await firebaseService.signInWithEmail(email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try firebaseService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleSignUpMode() {
        isSignUp.toggle()
        errorMessage = nil
    }
}

