//
//  RegisterView.swift
//  Unity
//
//  Created by Neil Thakkar on 02/09/2024.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import _PhotosUI_SwiftUI

struct RegisterView: View {
    @State var Status: String = "Mentor-Undergrad"
    @State var Email: String = ""
    @State var Password: String = ""
    @State var UserName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilePicData: Data?
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var createdAcc: Bool = false
    @State var isLoading: Bool = false
    @AppStorage ("log_status") var logStatus: Bool = false
    @AppStorage ("user_profile_url") var profileURL: URL?
    @AppStorage ("user_name" ) var StoredUserName: String = ""
    @AppStorage ("user_UID") var userUID: String = ""

    var body: some View{
        VStack(spacing: 12){
            Text("Register an account")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text("Welcome To GradLink\nPlease fill out the following details")
                .hAlign(.leading)
            
            ViewThatFits{
                ScrollView(.vertical, showsIndicators: false){
                    HelperView()
                }
                HelperView()
            }
            .vAlign(.top)
            .padding(10)
            
            HStack{
                Text("Already have an account ?")
                    .foregroundColor(.gray)
                Button("Log in"){
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
                
            }
            .vAlign(.bottom)
        }
        .padding(10)
        .overlay(content:{
            LoadingView(show: $isLoading)
        })
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) {
            if let newValue = photoItem {
                Task {
                    do {
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else { return }
                        await MainActor.run {
                            userProfilePicData = imageData
                        }
                    } catch {
                        // Handle the error
                    }
                }
            }
        }

        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    @ViewBuilder
    func HelperView()->some View{
        VStack(spacing: 12){
            ZStack{
                if let userProfilePicData, let image = UIImage(data: userProfilePicData){
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                }else{
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                }
                
            }
            .clipShape(Circle())
            .frame(width: 150, height: 150)
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top,15)
            
            TextField("Username", text: $UserName)
                .hAlign(.leading)
                .textContentType(.emailAddress)
                .border(_width: 2,.gray.opacity(0.5))
            
            TextField("Email", text: $Email)
                .hAlign(.leading)
                .textContentType(.emailAddress)
                .border(_width: 2,.gray.opacity(0.5))
            
            SecureField("Password",text: $Password)
                .hAlign(.leading)
                .textContentType(.emailAddress)
                .border(_width: 2,.gray.opacity(0.5))
            
            TextField("About you", text: $userBio)
                .frame(minHeight: 100,alignment: .top)
                .hAlign(.leading)
                .textContentType(.emailAddress)
                .border(_width: 2,.gray.opacity(0.5))
            
            TextField("Bio Link (optional)", text: $userBioLink)
                .hAlign(.leading)
                .textContentType(.emailAddress)
                .border(_width: 2,.gray.opacity(0.5))
            
            Button(action: registerUser){
                Text("Sign In")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.black)
                    .disableWithOpacity(UserName == "" || userBio == "" || Email == "" || userProfilePicData == nil)
                    .alert(isPresented: $createdAcc, content: {
                        Alert(title: Text("Account has been created"))
                    })
            }
            
        }
        .vAlign(.top)
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    func registerUser(){
        isLoading = true
        closedKeyboard()
        Task{
            do{
                try await Auth.auth().createUser(withEmail: Email, password: Password)
                guard let UserUID = Auth.auth().currentUser?.uid else{return}
                guard let imageData = userProfilePicData else{return}
                let storageRef =  Storage.storage().reference().child("Profile_Images").child(UserUID)
                let _ = try await storageRef.putDataAsync(imageData)
                print("hello")
                let downloadURL = try await storageRef.downloadURL()
                let user = User (username: UserName, userBio: userBio, userBioLink: userBioLink,userUID: UserUID, userEmail: Email, userProfileURL: downloadURL)
                print("Attempting to save user data to Firestore")
                let _ = try Firestore.firestore().collection("Users").document(UserUID).setData(from: user)
                let documentSnapshot = try await Firestore.firestore().collection("Users").document(UserUID).getDocument()
                if documentSnapshot.exists {
                    print("User successfully added to Firestore")
                    StoredUserName = UserName
                    self.userUID = UserUID
                    profileURL = downloadURL
                    logStatus  = true
                    if logStatus == true{
                        print("Hello2")
                        isLoading = false
                    }
                }
            }catch{
                await setError(error)
                isLoading = false
            }
            
        }
    }
    
    
    func setError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}
