//
//  macOSPostExpandedView.swift
//  EveningReading (macOS)
//
//  Created by Chris Hodge on 6/10/21.
//

import SwiftUI

struct macOSPostExpandedView: View {
    @EnvironmentObject var appService: AppService
    @EnvironmentObject var chatService: ChatService
    @Binding var postId: Int
    @Binding var postAuthor: String
    @Binding var replyLines: String?
    @Binding var lols: [ChatLols]
    @Binding var postText: [RichTextBlock]
    @Binding var postDateTime: String
    @Binding var op: String
    
    var body: some View {
        HStack {
            // Reply lines
            if self.replyLines != nil {
                HStack(spacing: 0) {
                    ForEach(Array(self.replyLines!.enumerated()), id: \.offset) { index, character in
                        Text(String(character))
                            .lineLimit(1)
                            .fixedSize()
                            .font(.custom("replylines", size: 25, relativeTo: .callout))
                            .foregroundColor(Color("replyLines"))
                            .overlay(
                                Text(
                                    self.postId == chatService.activePostId && self.replyLines!.count - 1 == index && index > 0 ? String(character) : ""
                                )
                                .lineLimit(1)
                                .fixedSize()
                                .font(.custom("replylines", size: 25, relativeTo: .callout))
                                .foregroundColor(Color.red)
                            )
                    }
                }
            }
            
            // Author
            AuthorNameView(name: self.postAuthor, postId: self.postId, op: self.op)
            
            Spacer()
            
            // Lols
            LolView(lols: self.lols, expanded: true, postId: self.postId)
        }
        HStack {
            VStack (alignment: .leading) {
                // Full post
                RichTextView(topBlocks: appService.blockedAuthors.contains(self.postAuthor) ? RichTextBuilder.getRichText(postBody: "[blocked]") : self.postText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(8)

                if appService.isSignedIn && !appService.blockedAuthors.contains(self.postAuthor) {
                    HStack {
                        Text(postDateTime.postTimestamp())
                            .font(.caption)
                            .foregroundColor(Color("NoDataLabel"))
                        Spacer()
                        macOSPostActionsView(name: self.postAuthor, postId: self.postId, showingHideThread: false)
                        macOSTagPostButton(postId: self.postId)
                        Image(systemName: "link")
                            .imageScale(.large)
                            .onTapGesture(count: 1) {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString("https://www.shacknews.com/chatty?id=\(self.postId)#item_\(self.postId)", forType: .URL)
                                chatService.didCopyLink = true
                            }
                        Image(systemName: "arrowshape.turn.up.left")
                            .imageScale(.large)
                            .onTapGesture(count: 1) {
                                chatService.newPostParentId = self.postId
                                chatService.newReplyAuthorName = self.postAuthor
                                chatService.showingNewPostSheet = true
                            }
                    }
                    .padding(.bottom, 8)
                    .padding(.horizontal, 8)
                } else {
                    HStack {
                        Text(postDateTime.postTimestamp())
                            .font(.caption)
                            .foregroundColor(Color("NoDataLabel"))
                        Spacer()
                        macOSPostActionsView(name: self.postAuthor, postId: self.postId, showingHideThread: false)
                    }
                    .padding(.bottom, 8)
                    .padding(.horizontal, 8)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color("ThreadBubblePrimary"))
        .cornerRadius(5)
    }
}
