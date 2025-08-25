//
//  LoginVeiw.swift
//  Unity
//
//  Created by Neil Thakkar on 07/08/2024.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
struct LoginView: View {
    
    @State var Email = ""
    @State var Password = ""
    @State var errorMessage: String = "Hello"
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    @AppStorage ("log_status") var logStatus: Bool = false
    @AppStorage ("user_profile_url") var profileURL: URL?
    @AppStorage ("user_name" ) var StoredUserName: String = ""
    @AppStorage ("user_UID") var userUID: String = ""
    var body: some View {
        VStack(spacing: 12){
            Text("Log in")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text("Welcome To GradLink\nPlease sign in to continue")
                .hAlign(.leading)
            VStack(spacing: 12){
                TextField("Email", text: $Email)
                    .hAlign(.leading)
                    .textContentType(.emailAddress)
                    .border(_width: 1,.gray.opacity(0.5))
                
                SecureField("Password",text: $Password)
                    .hAlign(.leading)
                    .textContentType(.emailAddress)
                    .border(_width: 1,.gray.opacity(0.5))
                
                Button("Forgot Password?", action: resetPassword)
                    .font(.callout)
                    .fontWeight(.medium)
                
                Button(action: loginUser){
                    Text("Sign In")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                
                HStack{
                    Text("Dont have an account")
                        .foregroundColor(.gray)
                    Button("Sign Up"){
                        createAccount.toggle()
                        
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    
                }
                .vAlign(.bottom)
                .overlay(content:{
                    LoadingView(show: $isLoading)
                })
            }
        }
        .vAlign(.top)
        .padding(15)
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    func loginUser(){
        isLoading = true
        closedKeyboard()
        Task {
            do {
                try await Auth.auth().signIn(withEmail: Email, password: Password)
                print("User found")
                try await fetchUser()
            } catch {
                await setError(error)
            }
        }
    }
    
    func fetchUser()async throws{
        guard let userID = Auth.auth().currentUser?.uid else{return}
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        await MainActor.run(body: {
            userUID = userID
            StoredUserName = user.username
            profileURL = user.userProfileURL
            logStatus = true
            
        })
    }

    func setError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
    
    func resetPassword(){
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: Email)
                print("Link sent")
            } catch {
                await setError(error)
            }
        }
        
    }
}
    #Preview(){
        LoginView()
    }
