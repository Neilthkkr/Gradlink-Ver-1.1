//
//  User.swift
//  Unity
//
//  Created by Neil Thakkar on 21/08/2024.
//

import SwiftUI
import FirebaseFirestore
import Foundation

struct User: Encodable, Decodable,Identifiable {
    var id: String?
    var username: String
    var userBio: String
    var userBioLink: String
    var userUID: String
    var userEmail: String
    var userProfileURL : URL
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case userBio
        case userBioLink
        case userUID
        case userEmail
        case userProfileURL
    }
    
}
