//
//  ContentView.swift
//  Unity
//
//  Created by Neil Thakkar on 07/08/2024.
//
import SwiftUI

struct ContentView: View {
    // The @AppStorage property wrapper needs to be declared at the top level
    @AppStorage("log_status") var logStatus: Bool = false
    
    var body: some View {
        Group {
            if logStatus {
                MainView()
            } else {
                LoginView()
            }
            
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}
