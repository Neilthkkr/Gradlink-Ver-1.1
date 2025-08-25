//
//  PostCardView .swift
//  Unity
//
//  Created by Neil Thakkar on 24/10/2024.
//
import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct PostCardView_: View {
    var post: Post
    var onUpdate: (Post)->()
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var docListner: ListenerRegistration?
    var onDelete: ()->()
    var body: some View{
        HStack(alignment: .top, spacing: 12){
            WebImage(url: post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 6){
                Text(post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical,8)
                
                if let postImageURL = post.imageURL{
                    GeometryReader{
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
                PostInteraction()
                    .padding(.top, 10)
            }
        }
        .overlay(alignment: .topTrailing, content: {
            if post.userUID == userUID{
                Menu{
                    Button("Delete post", role: .destructive, action: deletePost)
                }label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundColor(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)
                
            }
        })
        .onAppear{
            if docListner == nil{
                guard let postID = post.id else{return}
                docListner = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({snapshot, error in if let snapshot{
                    if snapshot.exists{
                        if let updatedPost = try? snapshot.data(as: Post.self){
                            onUpdate(updatedPost)
                        }
                    }else{
                        
                        onDelete()
                        
                    }
                }
                })
            }
        }
        .onDisappear{
            if let docListner{
                docListner.remove()
                self.docListner = nil
            }
        }
        
        
    }
    
    @ViewBuilder
    func PostInteraction()->some View{
        HStack(spacing: 6){
            Button(action: likePost){
                Image(systemName: post.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            Button(action: dislikePost){
                Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .padding(.leading,25)
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .foregroundColor(.black)
        .padding(.vertical,8)
    }
    
    func likePost() {
        Task {
            guard let postID = post.id else { return } // Ensure postID is available
            
            if post.likedIDs.contains(userUID) {
                try? await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
            } else {
                try? await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID]),
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            }
        }
    }
    
    func dislikePost() {
        Task {
            guard let postID = post.id else { return } // Ensure postID is available
            
            if post.dislikedIDs.contains(userUID) {
                try? await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            } else {
                try? await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID]),
                    "dislikedIDs": FieldValue.arrayUnion([userUID])
                ])
            }
        }
    }
    
    func deletePost() {
        Task {
            do {
                // Check if the post has an image reference ID and if it's not empty
                if !post.imageReferenceID.isEmpty {
                    let storageRef = Storage.storage().reference().child("Post_Images").child(post.imageReferenceID)
                    try await storageRef.delete()  // Delete the image from Firebase Storage
                    print("Image deleted successfully")
                }

                // Safely unwrap the post id and delete the post document from Firestore
                guard let postID = post.id else {
                    print("Post ID is missing")
                    return
                }
                
                let postRef = Firestore.firestore().collection("Posts").document(postID)
                try await postRef.delete()  // Delete post document from Firestore
                
                print("Post deleted successfully")
            } catch {
                print("Error deleting post: \(error.localizedDescription)")
            }
        }
    }
}
