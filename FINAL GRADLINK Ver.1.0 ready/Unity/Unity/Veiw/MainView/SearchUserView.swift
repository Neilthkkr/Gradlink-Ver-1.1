//
//  SearchUserView.swift
//  Unity
//
//  Created by Neil Thakkar on 01/01/2025.
//
import SwiftUI
import Firebase
import FirebaseFirestore

struct SearchUserView: View {
    @State private var fetchedUsers: [User] = []
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if fetchedUsers.isEmpty && !searchText.isEmpty {
                    Text("No users found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(fetchedUsers) { user in
                        NavigationLink {
                            ReusableProfileContent(user: user)
                        } label: {
                            Text(user.username)
                                .font(.caption)
                                .hAlign(.leading)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Search User")
            .searchable(text: $searchText)
            .onSubmit(of: .search) {
                Task { await searchUsers() }
            }
            .onChange(of: searchText) {
                if searchText.isEmpty {
                    fetchedUsers = []
                } else {
                    Task {
                        await searchUsers()
                    }
                }
            }

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(.black)
                }
            }
        }
    }
    func searchUsers() async {
        guard !searchText.isEmpty else { return }

        do {
            print("Searching for: \(searchText.lowercased())")
            let queryUppercased = searchText.uppercased()
            let queryLowercased = searchText.lowercased()
            
            let query = Firestore.firestore().collection("Users")
                .whereField("username", isGreaterThanOrEqualTo: queryUppercased)
                .whereField("username", isLessThanOrEqualTo: queryLowercased)
                .limit(to: 20)
            
            let snapshot = try await query.getDocuments()

            print("Documents fetched: \(snapshot.documents.count)")
            for doc in snapshot.documents {
                print("Document Data: \(doc.data())")
            }

            let users = snapshot.documents.compactMap { doc -> User? in
                var user = try? doc.data(as: User.self)
                user?.id = doc.documentID
                return user
            }

            await MainActor.run {
                fetchedUsers = users
            }

        } catch {
            print("Error searching users: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SearchUserView()
}
