//
//  NewMessageView.swift
//  Unity
//
//  Created by Neil Thakkar on 07/01/2025.
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI

struct NewMessageView: View {
    let didSelctNewUser:(User) -> ()
    @Environment(\.presentationMode) var presentationMode
    @State private var users: [User] = []
    
    private func FetchAllUsers() async {
        do {
            let query = Firestore.firestore().collection("Users")
            let snapshot = try await query.getDocuments()
            
            // Debug: Print the number of documents fetched
            print("Documents fetched: \(snapshot.documents.count)")
            let fetchedUsers: [User] = try snapshot.documents.compactMap { document in
                var user = try document.data(as: User.self)
                user.id = document.documentID
                if user.userUID != Auth.auth().currentUser?.uid {
                    return user
                } else {
                    return nil
                }
            }

            print("Fetched users count: \(fetchedUsers.count)")
            
            //Update the state on the main thread
            await MainActor.run {
                  self.users = fetchedUsers
            }
        } catch {
            print("Error fetching users: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(users) { user in
                    Button{
                        didSelctNewUser(user)
                        presentationMode.wrappedValue
                            .dismiss()
                        
                    }label:{
                        HStack {
                            WebImage(url: user.userProfileURL)
                                .resizable()
                                .clipped()
                                .frame(width: 50, height: 50)
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50)
                                    .stroke(Color(.label), lineWidth: 1))
                                .padding()
                            VStack(alignment: .leading) {
                                Text(user.username)
                                    .font(.headline)
                                Text(user.userEmail)
                                    .font(.subheadline)
                            }
                            .hAlign(.leading)
                            .padding()
                        }
                    }
                    Divider()
                        .padding(8)
                }
                .navigationTitle("New Message")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
                .onAppear {
                    Task {
                        await FetchAllUsers()
                    }
                }
            }
        }
    }
}

#Preview {
    NewMessageView(didSelctNewUser: {
        user in 
    })
}
