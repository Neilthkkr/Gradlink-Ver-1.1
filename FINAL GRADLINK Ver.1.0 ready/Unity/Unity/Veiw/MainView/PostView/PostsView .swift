//
//  PostsView .swift
//  Unity
//
//  Created by Neil Thakkar on 04/10/2024.
//



import SwiftUI

struct PostsView_: View {
    @State private var recentPosts: [Post] = []
    @State private var createNewPost: Bool = false

    var body: some View {
        NavigationStack {
            ReusablePostsView_(posts: $recentPosts)
                .hAlign(.center)
                .vAlign(.center)
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        createNewPost.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(13)
                            .foregroundColor(.white)
                            .background(.black, in: Circle())
                    }
                    .padding(15)
                }
                .toolbar(content:{
                    ToolbarItem(placement: .navigationBarTrailing){
                        NavigationLink{
                            SearchUserView()
                        }label: {
                            Image(systemName: "magnifyingglass")
                                .tint(.black)
                                .scaleEffect(0.9)
                        }
                    }
                    
                })
                .navigationTitle("Posts")
        }
        .fullScreenCover(isPresented: $createNewPost) {
            CreateNewPost { post in
                // Ensure the post gets added to the top of the list
                recentPosts.insert(post, at: 0)
            }
        }
    }
}

#Preview {
    PostsView_()
}
 
