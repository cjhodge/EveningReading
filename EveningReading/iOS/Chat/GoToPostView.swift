//
//  GoToPostView.swift
//  EveningReading (iOS)
//
//  Created by Chris Hodge on 5/10/21.
//

import SwiftUI

struct GoToPostView: View {
    @EnvironmentObject var appSessionStore: AppSessionStore
    @EnvironmentObject var notifications: Notifications
    @EnvironmentObject var chatStore: ChatStore
    
    @State private var goToPostId: Int = 0
    @State private var showingPost: Bool = false
    //@State private var disabled: Bool = false
    //@State private var showingAlert: Bool = false

    var body: some View {
        VStack {
            Text("\(self.goToPostId) \(self.showingPost.description)")
            
            // Fixes navigation bug
            // https://developer.apple.com/forums/thread/677333
            NavigationLink(destination: EmptyView(), isActive: .constant(false)) {
                EmptyView()
            }.frame(width: 0, height: 0)
            NavigationLink(destination: EmptyView(), isActive: .constant(false)) {
                EmptyView()
            }.frame(width: 0, height: 0)
            
            // Push ThreadDetailView
            NavigationLink(destination: ThreadDetailView(threadId: .constant(0), postId: self.$goToPostId, replyCount: .constant(-1), isSearchResult: .constant(true)), isActive: self.$showingPost) {
                EmptyView()
            }
            
            // Deep link to specific shack post
            .onReceive(appSessionStore.$showingShackLink) { value in
                print(".onReceive(appSessionStore.$showingShackLink)")
                if value {
                    print("going to try to show link")
                    if appSessionStore.shackLinkPostId != "" {
                        print("showing link")
                        self.appSessionStore.showingShackLink = false
                        self.goToPostId = Int(appSessionStore.shackLinkPostId) ?? 0
                        self.showingPost = true
                    }
                }
            }

            // Deep link to post from push notification
            /*
            .onReceive(notifications.$notificationData) { value in
                print(".onReceive(notifications.$notificationData)")
                if let postId = value?.notification.request.content.userInfo["postid"] {
                    print("got postId \(postId), previously showed \(appSessionStore.showingPostId)")
                    if String("\(postId)").isInt && appSessionStore.showingPostId != Int(String("\(postId)")) ?? 0 {
                        print("setting postID \(postId)")
                        appSessionStore.showingPostId = Int(String("\(postId)")) ?? 0
                        DispatchQueue.main.async {
                            print("post id is really \(Int(String("\(postId)")) ?? 0)")
                            self.notifications.notificationData = nil
                            self.goToPostId = Int(String("\(postId)")) ?? 0
                            //self.showingPost = true
                            //self.showingAlert = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                            print("going to post \(postId)")
                            self.showingPost = true
                        }
                    }
                    /*
                    if !self.disabled && String("\(postId)").isInt {
                        self.disabled = true
                        self.notifications.notificationData = nil
                        self.goToPostId = Int(String("\(postId)")) ?? 0
                        self.showingPost = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                            self.disabled = false
                        }
                    }
                     */
                }
                /*
                print("got notification \(value)")
                if let notification = value?.notification.request.content.body {
                    print("got body \(body)")
                }
                */
            }
            */
            /*
            .alert(isPresented: self.$showingAlert) {
                Alert(title: Text("Notification Received"), message: Text("PostId"),
                      primaryButton: .default (Text("OK")) {
                        DispatchQueue.main.async {
                            self.showingPost = true
                        }
                      }, secondaryButton: .cancel()
                )
            }
            */
        }
        //.frame(width: 0, height: 0)
    }
}

struct GoToPostView_Previews: PreviewProvider {
    static var previews: some View {
        GoToPostView()
            .environmentObject(AppSessionStore(service: AuthService()))
            .environmentObject(Notifications())
            .environmentObject(ChatStore(service: ChatService()))
    }
}
