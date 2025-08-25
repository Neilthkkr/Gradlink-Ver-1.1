//
//  MessageView.swift
//  Unity
//
//  Created by Neil Thakkar on 04/01/2025.
//
import SwiftUI
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth


struct FirebaseConstants{
    static let fromID = "fromID"
    static let toID =  "toID"
    static let messagetext = "messagetext"
    static let timestamp = "timestamp"
    static let username = "username"
    static let userprofileurl = "userprofileurl"
}

struct Message: Identifiable {
    var id: String { documentId }
    let documentId: String
    let fromID: String
    let toID: String
    let messagetext: String
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.fromID = data[FirebaseConstants.fromID] as? String ?? ""
        self.toID = data[FirebaseConstants.toID] as? String ?? ""
        self.messagetext = data[FirebaseConstants.messagetext] as? String ?? ""
    }
}




struct MessageView: View {
    let user: User?
    @State private var messagetext: String = ""
    @State var Messages = [Message]()
    @State var scrolltoID = "bottom"
    
    var body: some View {
        VStack {
            ScrollViewReader{ proxy in
                ScrollView {
                    ForEach(Messages) { message in
                        if message.fromID == Auth.auth().currentUser?.uid {
                            HStack {
                                Spacer()
                                Text(message.messagetext)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black)
                                    .cornerRadius(20)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        } else {
                            HStack {
                                Text(message.messagetext)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(20)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    Spacer().id(scrolltoID)
                }
                .background(Color(.init(white: 0.95, alpha: 1)))
                .onChange(of: Messages.count){ _ in
                    withAnimation {
                        proxy.scrollTo(scrolltoID, anchor: .bottom)
                    }
            }
        }
            
            // Message Input Field
            HStack {
                Image(systemName: "photo.artframe.circle.fill")
                    .font(.system(size: 24))
                ZStack {
                    if messagetext.isEmpty {
                        Text("Enter your message here...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $messagetext)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .frame(height: 30)
                
                Button {
                    handleSend(text: messagetext)
                } label: {
                    Text("Send")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
                .frame(width: 50, height: 30)
                .background(Color.black)
                .cornerRadius(8)
            }
            .padding()
            
        }
        .onDisappear{
            MessageListView(recentMessages: [])
        }
        .navigationTitle(user?.username ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchMessages()
        }
    }
    
    private func PersistLastMessage(){
        guard let uid = Auth.auth().currentUser?.uid else{return}
        guard let toId = self.user?.id else {return}
        guard let username = user?.username else{return}
        guard let userprofileurl = user?.userProfileURL.absoluteString else {return}
        let document = Firestore.firestore()
            .collection("recent messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        let data = [
            FirebaseConstants.fromID : uid,
            FirebaseConstants.toID : toId,
            FirebaseConstants.messagetext: self.messagetext,
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.username: username,
            FirebaseConstants.userprofileurl: userprofileurl
        ] as [String : Any]
        
        document.setData(data){ error in
            if let error = error {
                print(error)
                return
            }
            
        }
    }
    
   
    func handleSend(text: String) {
        print(messagetext)
        guard let fromID = Auth.auth().currentUser?.uid else { return }
        guard let toID = user?.id else { return }

        // Create message data
        let messageData = [
            FirebaseConstants.fromID: fromID,
            FirebaseConstants.toID: toID,
            FirebaseConstants.messagetext: self.messagetext,
            "timestamp": Timestamp()
        ] as [String: Any]

        // Save message to Firestore for both sender and receiver
        let document = Firestore.firestore().collection("messages")
            .document(fromID).collection(toID).document()

        document.setData(messageData) { error in
            if let error = error {
                print("Error saving message: \(error)")
            } else {
                // Clear message input after sending
                PersistLastMessage()
                self.messagetext = ""
            }
        }
        
        // Save the message to the receiver's collection as well
        let recipientDocument = Firestore.firestore().collection("messages")
            .document(toID).collection(fromID).document()

        recipientDocument.setData(messageData) { error in
            if let error = error {
                print("Error saving message to receiver: \(error)")
            }
        }
    }

    func fetchMessages() {
        guard let fromID = Auth.auth().currentUser?.uid else { return }
        guard let toID = user?.id else { return }

        Firestore.firestore().collection("messages")
            .document(fromID)
            .collection(toID)
            .order(by: "timestamp") // Ensure messages are ordered by timestamp
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error)")
                } else {
                    // Iterate through document changes and append new messages
                    querySnapshot?.documentChanges.forEach { change in
                        if change.type == .added {
                            let data = change.document.data()
                            let docId = change.document.documentID
                            let message = Message(documentId: docId, data: data)

                            // Ensure new messages are added to the list
                            DispatchQueue.main.async {
                                self.Messages.append(message)
                            }
                        }
                    }
                }
            }
    }
}
