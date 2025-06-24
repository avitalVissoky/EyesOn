//
//  User.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import Foundation

struct User: Codable {
    let uid: String
    let email: String?
    let isAnonymous: Bool
    let isModerator: Bool
    let createdAt: Date
    
    init(uid: String, email: String?, isAnonymous: Bool = false, isModerator: Bool = false) {
        self.uid = uid
        self.email = email
        self.isAnonymous = isAnonymous
        self.isModerator = isModerator
        self.createdAt = Date()
    }
}
