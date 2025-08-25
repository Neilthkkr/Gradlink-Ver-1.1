//
//  ReusablePostsView .swift
//  Unity
//
//  Created by Neil Thakkar on 14/10/2024.
//
import SwiftUI
import Firebase

struct ReusablePostsView_: View {
    var BasedOnUID: Bool = false
    var uid: String = ""
    @Binding var posts: [Post]
    @State private var isFetching: Bool = true
    @State private var paginationDoc: QueryDocumentSnapshot?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 15) {
                if isFetching {
                    ProgressView().padding(.top, 30)
                } else if posts.isEmpty {
                    Text("No posts found")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 30)
                } else {
                    Posts()
                }
            }
            .padding(15)
        }
        .refreshable {
            guard !BasedOnUID else { return }
            isFetching = true
            posts = []
            paginationDoc = nil
            await fetchPosts()
        }
        .task {
            guard posts.isEmpty else { return }
            await fetchPosts()
        }
    }
    
    @ViewBuilder
    func Posts() -> some View {
        ForEach(posts, id: \.id) { post in
            PostCardView_(post: post) { updatedPost in
                if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs = updatedPost.dislikedIDs
                }
            } onDelete: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    posts.removeAll { $0.id == post.id }
                }
            }
            .onAppear {
                if post.id == posts.last?.id, paginationDoc != nil {
                    Task { await fetchPosts() }
                }
            }
            Divider()
        }
    }
    
    func fetchPosts() async {
        do {
            // Initialize the Firestore query
            var query = Firestore.firestore().collection("Posts")
                .order(by: "publishedDate", descending: true)
                .limit(to: 20)
            
            // Apply pagination document if available
            if let paginationDoc = paginationDoc {
                query = query.start(afterDocument: paginationDoc)
            }
            
            // Apply UID filter if applicable
            if BasedOnUID {
                print("Applying filter for user with UID: \(uid)")
                query = query.whereField("userUID", isEqualTo: uid)
            }
            
            // Execute the query
            print("Executing query for user ID: \(uid)")
            let snapshot = try await query.getDocuments()
            print("Documents fetched: \(snapshot.documents.count)")
            
            // Map Firestore documents to Post objects
            let fetchedPosts = snapshot.documents.compactMap { doc -> Post? in
                do {
                    var post = try doc.data(as: Post.self)
                    post.id = doc.documentID
                    return post
                } catch {
                    print("Error decoding document \(doc.documentID): \(error.localizedDescription)")
                    return nil
                }
            }
            
            // Update the UI on the main thread
            await MainActor.run {
                posts.append(contentsOf: fetchedPosts.filter { newPost in
                    !posts.contains { $0.id == newPost.id }
                })
                
                paginationDoc = snapshot.documents.last
                isFetching = false
            }
            
            // Debugging: Log the number of posts fetched
            print("Successfully fetched \(fetchedPosts.count) posts.")
        } catch {
            // Handle errors and update UI
            print("Error fetching posts from Firestore: \(error.localizedDescription)")
            await MainActor.run {
                isFetching = false
            }
        }
    }
}
