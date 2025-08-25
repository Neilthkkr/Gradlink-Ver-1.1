//
//  MainView.swift
//  Unity
//
//  Created by Neil Thakkar on 31/08/2024.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView{
            PostsView_()
                .tabItem {
                    Image(systemName: "paperplane.circle.fill")
                    Text("Posts")
                }
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.rectangle.fill")
                    Text("You")
                    
                    
                }
            MessageListView(recentMessages: [])
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Message")
                }
            
        }
    }
    
    #Preview {
        ContentView()
    }
}
