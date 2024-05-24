//
//  ComposePostView.swift
//  iOS
//
//  Created by Chris Hodge on 7/7/20.
//

import SwiftUI
import Photos

struct ComposePostView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appService: AppService
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var shackTagService: ShackTagService
    @EnvironmentObject var pushNotificationsService: PushNotificationsService
    
    public var isRootPost: Bool = false
    public var postId: Int = 0
    public var replyToPostBody = ""
    public var replyToAuthor = ""
    
    @State private var postBody = ""
    @State private var postStyle = UIFont.TextStyle.body

    @State private var showingComposeSheet = false

    @State private var showingLoading = false
    @State private var loadingMessage = "Loading"

    @State private var showingImageSheet = false
    @State private var uploadImage: UIImage?
    @State private var uploadImageFail = false

    @State private var showingSubmitAlert = false
    @State private var showingSubmitError = false
    
    @State private var showingTagMenu = false
    
    @State private var composePage = 0
    @State private var postWebViewHeight: CGFloat = .zero
    
    private func submitPost() {
        self.loadingMessage = "Submitting"
        self.showingLoading = true
        chatService.didSubmitPost = true
        
        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        if self.isRootPost {
            chatService.didSubmitNewThread = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                chatService.didGetChatStart = true
            }
        } else {
            chatService.didGetThreadStart = true
        }

        // Let the loading indicator show for at least a short time
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            chatService.submitPost(postBody: self.postBody, postId: self.postId)
            ShackTagService.shared.taggedText = ""
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(8)) {
            chatService.getThread()
            chatService.postsToHighlight.removeAll()
        }
    }

    private func showImageSheet() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) {
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .authorized:
                //handle authorized status
                self.showingImageSheet = true
                break
            case .denied, .restricted :
                //handle denied status
                break
            case .notDetermined:
                // ask for permissions
                PHPhotoLibrary.requestAuthorization { status in
                    switch status {
                    case .authorized:
                        // as above
                        self.showingImageSheet = true
                    case .denied, .restricted:
                        // as above
                        print("denied access to photos")
                        break
                    case .notDetermined:
                        // won't happen but still
                        print("undetermined photo access status")
                        break
                    case .limited:
                        print("unknown photo access error")
                    @unknown default:
                        print("unknown photo access error")
                    }
                }
            case .limited:
                print("unknown photo access error")
            @unknown default:
                print("unknown photo access error")
            }
        }
    }
    
    private func uploadImageToImgur(image: UIImage) {
        chatService.uploadImageToImgur(image: image, postBody: self.postBody) { success, body in
            if success {
                self.showingLoading = false
                self.uploadImageFail = false
                self.postBody = body
            } else {
                self.showingLoading = false
                self.uploadImageFail = true
            }
        }
    }
    
    private func clearComposeSheet() {
        DispatchQueue.main.async {
            chatService.submitPostSuccessMessage = ""
            chatService.submitPostErrorMessage = ""
            self.postBody = ""
            ShackTagService.shared.taggedText = ""
            self.showingLoading = false
            self.uploadImageFail = false
            self.showingComposeSheet = false
            self.showingTagMenu = false
            appService.showingComposeSheet = false
        }
    }
    
    var body: some View {
        VStack {
            Spacer().frame(width: 0, height: 0)

            // Compose Post Sheet
            .sheet(isPresented: self.$showingComposeSheet,
               onDismiss: {
                    print("Modal Dismissed")
               }) {
                VStack {
                    ZStack {
                        
                        // Heads up if it's going to be a new thread
                        if postId == 0 {
                            HStack {
                                Spacer()
                                Text("New Thread")
                                    .font(.body)
                                    .padding(.top, 10)
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text(String(self.postId))
                                    .font(.body)
                                    .padding(.top, 10)
                                Spacer()
                            }
                        }
                        
                        // Buttons
                        HStack {
                            Spacer().frame(width: 10)
                            
                            // Bail!
                            Button("Cancel") {
                                clearComposeSheet()
                            }
                            .foregroundColor(Color(UIColor.systemBlue))
                            
                            Spacer()

                            // Imgur Button
                            Button(action: {
                                if self.showingLoading || self.showingTagMenu {
                                    return
                                }
                                DispatchQueue.main.async {
                                    self.showingComposeSheet = false
                                    appService.showingComposeSheet = false
                                    self.uploadImageFail = false
                                    showImageSheet()
                                }
                            }) {
                                if self.uploadImageFail {
                                    Image(systemName: "photo")
                                        .foregroundColor(self.showingLoading ? Color(UIColor.systemGray3) : Color(UIColor.link))
                                        .overlay(Image(systemName: "exclamationmark").scaleEffect(0.75).padding(.top, -5).padding(.leading, 25).foregroundColor(Color(UIColor.systemRed)), alignment: .top)
                                } else {
                                    Image(systemName: "photo")
                                        .foregroundColor(self.showingLoading ? Color(UIColor.systemGray3) : Color(UIColor.link))
                                }
                            }
                            
                            Spacer().frame(width: 10)
                            
                            // Submit Post
                            Button("Submit") {
                                if self.showingLoading || self.postBody.count < 5 || self.showingTagMenu {
                                    return
                                }
                                withAnimation(.easeIn(duration: 0.05)) {
                                    self.showingSubmitAlert = true
                                }
                            }
                            .frame(width: 70, height: 30)
                            .foregroundColor(self.showingLoading || self.postBody.count < 5 ? Color(UIColor.systemGray3) : Color(UIColor.link))
                            
                            Spacer().frame(width: 10)
                        }
                        .padding(.top, 10)
                        
                    }
                    
                    // TextEditor
                    ZStack {
                        VStack {
                            if (!self.replyToPostBody.isEmpty) {
                                Picker("Select", selection: $composePage) {
                                    Text("Compose").tag(0)
                                    Text("Replying To").tag(1)
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, 10)
                            }
                            if (self.composePage == 0) {
                                ShackTagsTextView(text: self.$postBody, textStyle: self.$postStyle, doTagText: self.$showingTagMenu)
                                    .border(Color(UIColor.systemGray5))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                            } else {
                                ScrollView {
                                    HStack {
                                        PostWebView(viewModel: PostWebViewModel(author: self.replyToAuthor, body: self.replyToPostBody, colorScheme: colorScheme), dynamicHeight: $postWebViewHeight)
                                    }
                                    .frame(height: postWebViewHeight)
                                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                                }
                                .edgesIgnoringSafeArea(.bottom)
                            }
                        }

                        /*
                        // No way to change the background in supported iOS versions
                        if appService.isDarkMode {
                            TextEditor(text: self.$postBody)
                                .border(Color(UIColor.systemGray5))
                                .cornerRadius(4.0)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                        } else if colorScheme == .light {
                            TextEditor(text: self.$postBody)
                                .border(Color(UIColor.systemGray5))
                                .cornerRadius(4.0)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                        } else {
                            TextEditor(text: self.$postBody)
                                .border(Color(UIColor.systemGray5))
                                .cornerRadius(4.0)
                                .colorInvert()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                        }
                        */

                        // Loading indicator
                        LoadingView(show: self.$showingLoading, title: self.loadingMessage)
                        
                        // Dim the text editor
                        if self.showingLoading || self.showingSubmitAlert {
                            Rectangle()
                                .fill(Color(UIColor.systemGray))
                                .frame(maxWidth:.infinity, maxHeight: .infinity)
                                .padding(.all, 5)
                                .cornerRadius(5)
                                .opacity(0.1)
                        }
                        
                        // Shack tags
                        TagTextView(shown: self.$showingTagMenu)
                        
                        // Can't show a real alert on top of a sheet
                        AlertView(shown: self.$showingSubmitAlert, alertAction: .constant(.others), message: "Submit post?", cancelOnly: false, confirmAction: {
                            self.submitPost()
                        })
                        
                        // Some kind of posting error
                        AlertView(shown: self.$showingSubmitError, alertAction: .constant(.others), message: "Error Posting", cancelOnly: true, confirmAction: {
                            chatService.submitPostSuccessMessage = ""
                            chatService.submitPostErrorMessage = ""
                        })
                    }
                    Spacer()                    
                }
                .background(appService.isDarkMode ? Color("PrimaryBackgroundDarkMode").frame(height: BackgroundHeight).offset(y: BackgroundOffset) : Color.clear.frame(height: BackgroundHeight).offset(y: BackgroundOffset))
                .interactiveDismissDisabled()
            }
            // End Compose Post Sheet
            
            // Image Picker Sheet
            .sheet(isPresented: $showingImageSheet,
                   onDismiss: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) {
                            self.showingComposeSheet = true
                            appService.showingComposeSheet = true
                            if self.uploadImage != nil {
                                uploadImageToImgur(image: self.uploadImage!)
                            } else {
                                self.uploadImageFail = false
                            }
                        }
                   }) {
                ImagePickerView(sourceType: .photoLibrary) { image in
                    self.uploadImage = image
                    self.showingImageSheet = false
                    self.showingLoading = true
                    self.loadingMessage = "Uploading"
                }
            }
            
            // Post Success
            .onReceive(chatService.$submitPostSuccessMessage) { successMsg in
                if successMsg != "" {
                    DispatchQueue.main.async {
                        chatService.submitPostSuccessMessage = ""
                        chatService.submitPostErrorMessage = ""
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
                        self.postBody = ""
                        self.showingLoading = false
                        self.showingComposeSheet = false
                        appService.showingComposeSheet = false
                    }
                }
            }
            
            // Post Fail
            .onReceive(chatService.$submitPostErrorMessage) { errorMsg in
                if errorMsg != "" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
                        self.showingLoading = false
                        self.showingSubmitError = true
                    }
                }
            }

            // Tag some text
            .onReceive(shackTagService.$doTagText) { value in
                if value {
                    self.showingTagMenu = true
                }
            }
            
            // If shack tags were added
            .onReceive(ShackTagService.shared.$taggedText) { value in
                if value != "" {
                    self.postBody = value
                }
            }
                
            // If push notification tapped
            .onReceive(pushNotificationsService.$notificationData) { value in
                if value != nil {
                    clearComposeSheet()
                }
            }
            
            // Hide TagTextView
            .onAppear() {
                self.showingTagMenu = false
            }
            
            // Button style is different depending on context
            if appService.isSignedIn {
                Button(action: {
                    DispatchQueue.main.async {
                        self.showingComposeSheet = true
                        appService.showingComposeSheet = true
                        print(self.showingComposeSheet)
                    }
                }) {
                    ZStack {
                        if !self.isRootPost {
                            Image(systemName: "circle.fill")
                                .font(.title)
                                .foregroundColor(Color("ActionButton"))
                                .shadow(color: Color("ActionButtonShadow"), radius: 4, x: 0, y: 0)
                        }
                        Image(systemName: self.isRootPost ? "square.and.pencil" : "arrowshape.turn.up.left")
                            .imageScale(!self.isRootPost ? .medium : .large)
                            .foregroundColor(self.colorScheme == .dark ? Color(UIColor.white) : Color(UIColor.systemBlue))
                    }
                }
                .buttonStyle(.plain)
            }
            
        }
    }
}
