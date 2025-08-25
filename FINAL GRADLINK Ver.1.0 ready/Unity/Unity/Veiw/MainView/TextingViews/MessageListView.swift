//
//  MessageListView.swift
//  Unity
//
//  Created by Neil Thakkar on 05/01/2025.
//
import SwiftUI
import Firebase
import SDWebImageSwiftUI
import FirebaseAuth

struct RecentMessage: Identifiable{
    var id: String { documentId }
    let documentId: String
    let fromID: String
    let toID: String
    let messagetext: String
    let username,userprofileurl: String
    let timestamp : Timestamp
    init(documentId: String, data: [String: Any]){
        self.documentId = documentId
        self.fromID = data["fromID"] as? String ?? ""
        self.toID = data["toID"] as? String ?? ""
        self.messagetext = data["messagetext"] as? String ?? ""
        self.username = data["username"] as? String ?? ""
        self.userprofileurl = data["userprofileurl"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
    }
}

struct MessageListView: View {
    @State private var user: User? = nil
    @State private var showNewMessage: Bool = false
    @State private var shouldNavigateToChatLogView: Bool = false
    @State private var isNewMessageButtonVisible: Bool = true // New state for button visibility
    @State var recentMessages: [RecentMessage]
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    MessageView(user: self.user)
                }
                
                CustomNavBar
                MessageMainView
            }
        }
        .overlay(
            // Only show NewMessageButton if isNewMessageButtonVisible is true
            isNewMessageButtonVisible ? NewMessageButton : nil,
            alignment: .bottom
        )
        .navigationBarHidden(true)
        .onAppear {
            fetchLoggedInUser()
            self.isNewMessageButtonVisible = true
        }
    }
    
    private var CustomNavBar: some View {
        VStack(alignment: .leading) {
            if let user = user {
                HStack(spacing: 16) {
                    WebImage(url: user.userProfileURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .padding(8)
                        .font(.system(size: 32))
                        .overlay(
                            RoundedRectangle(cornerRadius: 44)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    
                    Text(user.username)
                        .font(.system(size: 24, weight: .bold))
                }
            } else {
                ProgressView("Loading user...")
            }
        }
    }
    
    private var NewMessageButton: some View {
        Button {
            self.showNewMessage = true
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.black)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 10)
        }
        .fullScreenCover(isPresented: $showNewMessage) {
            NewMessageView(didSelctNewUser: { selectedUser in
                // Assign the selected user
                self.user = selectedUser

                // Navigate after ensuring the modal is dismissed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.shouldNavigateToChatLogView = true
                    // Hide the NewMessageButton
                    self.isNewMessageButtonVisible = false
                }
                
     
                
                // Automatically show the NewMessageButton again after the modal closes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                }
            })
        }
    }
    
    private var MessageMainView: some View {
        let characterLimit: Int = 50
        return ScrollView {
            ForEach(recentMessages) { recentMessage in
                NavigationLink {
                    MessageView(user: self.user)
                } label: {
                    HStack {
                        WebImage(url: URL(string: recentMessage.userprofileurl))
                            .resizable()
                            .scaledToFill()  // Use scaledToFill for proper image scaling
                            .frame(width: 50, height: 50) // Fixing size to ensure it's consistent
                            .clipShape(Circle())  // Make sure the image is circular
                            .overlay(
                                RoundedRectangle(cornerRadius: 44)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                            .padding(8)  // Padding for a better look
                        VStack(alignment: .leading) {
                            Text(recentMessage.username)
                                .font(.system(size: 14, weight: .semibold))
                            Text(recentMessage.messagetext)
                                .font(.callout)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        Text("Mon: 12:00AM")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.trailing)
                    }
                    Divider()
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
        self.isNewMessageButtonVisible = true
        fetchRecentMessages()
        fetchLoggedInUser()
    }
    }
    
    // Fetch logged-in user data from Firestore
    private func fetchLoggedInUser() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No logged-in user.")
            return
        }
        Firestore.firestore().collection("Users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data() else {
                print("No user data found.")
                return
            }
            do {
                user = try Firestore.Decoder().decode(User.self, from: data)
            } catch {
                print("Error decoding user data: \(error.localizedDescription)")
            }
        }
        isNewMessageButtonVisible = true
    }
    private func fetchRecentMessages(){
        guard let uid = Auth.auth().currentUser?.uid else{return}
        Firestore.firestore()
            .collection("recent messages")
            .document(uid)
            .collection("messages")
            .addSnapshotListener{QuerySnapshot, error in
                if let error = error{
                    print(error)
                    return
                }
                QuerySnapshot?.documentChanges.forEach({ change in
                        let docId = change.document.documentID
                    if let index = self.recentMessages.firstIndex(where: {recentMessages in return recentMessages.documentId == docId}){
                        self.recentMessages.remove(at: index )
                    }
                    self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at: 0)
                })
            }
    }
}
