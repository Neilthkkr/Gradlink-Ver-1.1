//
//  UnityApp.swift
//  Unity
//
//  Created by Neil Thakkar on 07/08/2024.
//

import SwiftUI
import Firebase
@main
struct UnityApp: App {
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

