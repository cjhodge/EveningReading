//
//  TagPostView.swift
//  iOS
//
//  Created by Chris Hodge on 7/15/20.
//

import SwiftUI

struct TagPostView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appService: AppService
    @EnvironmentObject var chatService: ChatService
    
    var postId: Int
    
    @State private var showingTagActionSheet = false
    @State private var tag = ""
    
    // Tag or untag a post
    private func tagPost(_ tag: String) {
        let user: String? = KeychainWrapper.standard.string(forKey: "Username")
        
        var userTagsForPost = [String: Int]()
        for tag in PostTag.allCases {
            userTagsForPost[tag.rawValue] = 0
        }
        
        // Find out if we are tagging or untagging then proceed
        chatService.getRaters(postId: postId, completionSuccess: {
                // Check if user already tagged
                for rater in chatService.raters {
                    for username in rater.usernames {
                        if username == user {
                            if let userTagged = PostTagHelper().postTagCode[rater.tag] {
                                userTagsForPost[userTagged] = 1
                            }
                        }
                    }
                }
                
                // Tag or untag
                if (userTagsForPost[tag] ?? 0 < 1) {
                    chatService.tag(postId: self.postId, tag: tag, untag: "0")
                    chatService.taggingNoticeText = "Tagged!"
                    chatService.tagDelta[self.postId, default: [:]][tag] = 1
                    chatService.tagRemovedDelta[self.postId, default: [:]][tag] = 0
                } else {
                    chatService.tag(postId: self.postId, tag: tag, untag: "1")
                    chatService.taggingNoticeText = "Untagged!"
                    chatService.tagDelta[self.postId, default: [:]][tag] = 0
                    chatService.tagRemovedDelta[self.postId, default: [:]][tag] = 1
                }
                
                // Show notice
                DispatchQueue.main.async {
                    chatService.didTagPost = true
                    chatService.showingTagNotice = true
                }
            }, completionFail: {
                if !(userTagsForPost[tag] ?? 0 > 0) {
                    chatService.tag(postId: self.postId, tag: tag, untag: "0")
                    chatService.taggingNoticeText = "Tagged!"
                    chatService.tagDelta[self.postId, default: [:]][tag] = 1
                    chatService.tagRemovedDelta[self.postId, default: [:]][tag] = 0
                } else {
                    chatService.tag(postId: self.postId, tag: tag, untag: "1")
                    chatService.taggingNoticeText = "Untagged!"
                    chatService.tagDelta[self.postId, default: [:]][tag] = 0
                    chatService.tagRemovedDelta[self.postId, default: [:]][tag] = 1
                }
                DispatchQueue.main.async {
                    chatService.didTagPost = true
                    chatService.showingTagNotice = true
                }
            }
        )
    }
    
    // Make tag action sheet
    private func getTagActionSheet() -> ActionSheet {
        let buttons = PostTag.allCases.enumerated().map { i, option in
            Alert.Button.default(Text(option.rawValue), action: { self.tagPost(option.rawValue) } )
        }
        return ActionSheet(title: Text("Tags"),
                       buttons: buttons + [Alert.Button.cancel()])
    }

    var body: some View {
        VStack {
            Menu {
                ForEach(PostTag.allCases, id: \.rawValue) { tag in
                    Button(action: { self.tagPost(tag.rawValue) }) {
                        Label(tag.rawValue, systemImage: "tag")
                        //Label(tag.rawValue, systemImage: "circle")
                        //Label(tag.rawValue, systemImage: "checkmark.circle")
                    }
                }
            }
            label: {
                ZStack {
                    Image(systemName: "circle.fill")
                        .font(.title)
                        .foregroundColor(Color("ActionButton"))
                        .shadow(color: Color("ActionButtonShadow"), radius: 4, x: 0, y: 0)
                    Image(systemName: "tag")
                        .imageScale(.medium)
                        .foregroundColor(self.colorScheme == .dark ? Color(UIColor.white) : Color(UIColor.systemBlue))
                }
            }
            /*
            Button(action: {
                chatService.didTagPost = false
                self.showingTagActionSheet = true
            }) {
                ZStack{
                    Image(systemName: "circle.fill")
                        .font(.title)
                        .foregroundColor(Color("ActionButton"))
                        .shadow(color: Color("ActionButtonShadow"), radius: 4, x: 0, y: 0)
                    Image(systemName: "tag")
                        .imageScale(.medium)
                        .foregroundColor(self.colorScheme == .dark ? Color(UIColor.white) : Color(UIColor.systemBlue))
                }
            }
            .actionSheet(isPresented: self.$showingTagActionSheet)
            {
                getTagActionSheet()
            }
            */
        }
    }
}
