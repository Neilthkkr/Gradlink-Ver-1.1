//
//  CreateNewPost.swift
//  Unity
//
//  Created by Neil Thakkar on 20/09/2024.
import PhotosUI
import Firebase
import FirebaseStorage
import SwiftUI

struct CreateNewPost: View {
    var onPost: (Post) -> ()
    
    @State private var PostText: String = ""
    @State private var postImageData: Data? = nil
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var StoredUserName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var showKeyboard: Bool
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false

    var body: some View {
        VStack {
            HStack {
                Menu {
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.black)
                }
                .hAlign(.leading)
                
                Button(action: createPost) {
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(15)
                        .background(.black, in: Capsule())
                }
                .disabled(PostText.isEmpty)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    TextField("Text...", text: $PostText, axis: .vertical)
                        .focused($showKeyboard)
                    if let postImageData = postImageData, let image = UIImage(data: postImageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        self.postImageData = nil
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .fontWeight(.bold)
                                        .tint(.red)
                                }
                                .padding(10)
                            }
                    }
                }
                .padding(15)
            }
            
            Divider()
            
            HStack {
                Button {
                    showImagePicker.toggle()
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                        .foregroundColor(.black)
                }
                .hAlign(.leading)
                
                Button("Done") {
                    showKeyboard = false
                }
            }
            .padding(15)
        }
        .vAlign(.top)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { oldValue, newValue in
            if let newValue {
                Task {
                    if let rawImageData = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: rawImageData),
                       let compressedImageData = image.jpegData(compressionQuality: 0.5) {
                        
                        await MainActor.run {
                            postImageData = compressedImageData
                            photoItem = nil
                        }
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
        .overlay {
            LoadingView(show: $isLoading)
        }
    }

    func createPost() {
        isLoading = true
        showKeyboard = false
        Task {
            do {
                guard let profileURL = profileURL else {
                    throw NSError(domain: "Profile URL is missing", code: 404, userInfo: nil)
                }
                
                let imageReferenceID = "\(userUID)\(Date())"
                let storageRef = Storage.storage().reference().child("Post_images").child(imageReferenceID)
                
                if let postImageData {
                    let _ = try await storageRef.putDataAsync(postImageData)
                    let downloadURL = try await storageRef.downloadURL()
                    
                    let post = Post(
                        text: PostText,
                        imageURL: downloadURL,
                        imageReferenceID: imageReferenceID,
                        userName: StoredUserName,
                        userUID: userUID,
                        userProfileURL: profileURL
                    )
                    
                    try await createDocumentAtFirebase(post)
                } else {
                    let post = Post(
                        text: PostText,
                        userName: StoredUserName,
                        userUID: userUID,
                        userProfileURL: profileURL
                    )
                    try await createDocumentAtFirebase(post)
                }
            } catch {
                await setError(error)
            }
            // Ensure that loading is set to false after the entire process
            isLoading = false
        }
    }

    func createDocumentAtFirebase(_ post: Post) async throws {
        do {
            let doc = Firestore.firestore().collection("Posts").document()
            let docRef = Firestore.firestore().collection("Posts").document()
            var postWithID = post
            postWithID.id = docRef.documentID
            try await docRef.setData(from: postWithID)
            onPost(postWithID)
            dismiss()
        } catch {
            // Handle errors
            throw error
        }
    }


    func setError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            showError.toggle()
        }
    }
}
  
