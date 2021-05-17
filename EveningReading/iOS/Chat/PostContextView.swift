//
//  PostContextView.swift
//  EveningReading (iOS)
//
//  Created by Chris Hodge on 5/9/21.
//

import SwiftUI

struct PostContextView: View {
    @EnvironmentObject var appSessionStore: AppSessionStore
    @EnvironmentObject var chatStore: ChatStore
    @EnvironmentObject var messageStore: MessageStore
    
    @Binding var showingWhosTaggingView: Bool
    @Binding var showingNewMessageView: Bool

    @Binding var messageRecipient: String
    @Binding var messageSubject: String
    @Binding var messageBody: String
    
    @Binding var collapsed: Bool
    
    var author: String = ""
    var postId: Int = 0
    var threadId: Int = 0
    
    var body: some View {
        Button(action: {
            self.showingWhosTaggingView = true
        }) {
            Text("Who's Tagging?")
            Image(systemName: "tag.circle")
        }
        if self.threadId > 0 {
            Button(action: {
                self.collapsed = true
                appSessionStore.collapsedThreads.append(self.threadId)
            }) {
                Text("Hide Thread")
                Image(systemName: "eye.slash")
            }
        }
        Button(action: {
            self.messageRecipient = self.author
            self.messageSubject = ""
            self.messageBody = ""
            self.showingNewMessageView = true
        }) {
            Text("Message Author")
            Image(systemName: "envelope.circle")
        }
        /*
        Button(action: {
            print("button")
        }) {
            Text("Search Author")
            Image(systemName: "magnifyingglass.circle")
        }
        */
        Button(action: {
            appSessionStore.blockedAuthors.append(self.author)
        }) {
            Text("Block User")
            Image(systemName: "exclamationmark.circle")
        }
        Button(action: {
            self.messageRecipient = "Duke Nuked"
            self.messageSubject = "Reporting Author of Post"
            self.messageBody = messageStore.getComplaintText(author: self.author, postId: self.postId)
            self.showingNewMessageView = true
        }) {
            Text("Report User")
            Image(systemName: "exclamationmark.circle")
        }
        .onAppear() {
            chatStore.activePostId = self.postId
        }
    }
}

struct PostContextView_Previews: PreviewProvider {
    static var previews: some View {
        PostContextView(showingWhosTaggingView: .constant(false), showingNewMessageView: .constant(false), messageRecipient: .constant(""), messageSubject: .constant(""), messageBody: .constant(""), collapsed: .constant(false))
            .environmentObject(AppSessionStore(service: AuthService()))
            .environmentObject(ChatStore(service: ChatService()))
            .environmentObject(MessageStore(service: MessageService()))
    }
}