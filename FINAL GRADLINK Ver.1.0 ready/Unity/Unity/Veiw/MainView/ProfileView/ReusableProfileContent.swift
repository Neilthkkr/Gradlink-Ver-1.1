//
//  ReusableProfileContent.swift
//  Unity
//
//  Created by Neil Thakkar on 16/09/2024.
//

import SwiftUI
import SDWebImageSwiftUI

struct ReusableProfileContent: View {
    var user: User
    @State private var fetchedPosts: [Post] = []
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack{
                HStack(spacing: 12){
                    WebImage(url: user.userProfileURL)
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                        .clipShape(Circle())
                        .padding(20)
                        .contentShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6){
                        Text(user.username)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(user.userBio)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(3)
                        
                        NavigationLink(destination: MessageView(user: user.self)){
                            HStack{
                                Image(systemName: "message.fill")
                                    .padding(.leading)
                                Text("Invite")
                                    .padding(.trailing)
                                
                            }
                            .padding()
                            .background(.black)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(lineWidth: 10)
                            )
                        }
                        .foregroundColor(.white)
                        .cornerRadius(100)
                        
                        if let bioLink = URL(string: user.userBioLink){
                            Link(user.userBioLink, destination: bioLink)
                                .font(.callout)
                                .tint(.blue)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Text("Posts")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical,15)
                    .padding(.horizontal,15)
                
                ReusablePostsView_(BasedOnUID: true, uid: user.userUID, posts: $fetchedPosts)
            }
        }
    }
}


