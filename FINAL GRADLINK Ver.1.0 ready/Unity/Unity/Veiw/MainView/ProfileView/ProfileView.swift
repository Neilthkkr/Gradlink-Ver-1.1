//
//  ProfileView.swift
//  Unity
//
//  Created by Neil Thakkar on 02/09/2024.
//
import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    @State var myProfile: User?
    @AppStorage ("log_status") var logStatus: Bool = false
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                if let myProfile {
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            self.myProfile = nil
                            await fetchUserData()
                        }
                }
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Logout", action: logOutUser)
                        Button("Delete Account", role: .destructive, action: DeleteAccount)
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
            .overlay {
                LoadingView(show: $isLoading)
            }
            .alert(errorMessage, isPresented: $showError, actions: {})
        }
        .task {
            if myProfile == nil {
                await fetchUserData()
            }
        }
    }

    func logOutUser() {
        try? Auth.auth().signOut()
        logStatus = false
    }

    func DeleteAccount() {
        Task {
            do {
                guard let UserUID = Auth.auth().currentUser?.uid else { return }
                let reference = Storage.storage().reference().child(UserUID)
                
                // Delete user's storage
                try await reference.delete()
                
                // Delete user's Firestore document
                try await Firestore.firestore().collection("Users").document(UserUID).delete()
                
                // Delete user from Auth
                try await Auth.auth().currentUser?.delete()
                
                logStatus = false
            } catch {
                await setError(error)
            }
        }
    }

    func fetchUserData() async {
        guard let UserUID = Auth.auth().currentUser?.uid else { return }
        
        do {
            let user = try await Firestore.firestore().collection("Users").document(UserUID).getDocument(as: User.self)
            
            await MainActor.run {
                myProfile = user
            }
        } catch {
            await setError(error)
        }
    }

    func setError(_ error: Error) async {
        await MainActor.run {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        }
    }
}

#Preview {
    ContentView()
}

