//
//  PostPreviewView.swift
//  EveningReading (iOS)
//
//  Created by Chris Hodge on 5/11/21.
//

import SwiftUI

struct PostPreviewView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appService: AppService
    @EnvironmentObject var chatService: ChatService
    
    var username: String
    var postId: Int
    var parentId: Int
    var postBody: String
    var replyLines: String
    var postCategory: String
    var postStrength: Double?
    var postAuthor: String
    var postLols: [ChatLols]
    var op: String = ""
    @Binding var selectedPostDepth: Int

    var body: some View {
        HStack {
            // Reply lines for eaiser reading
            HStack(spacing: 0) {
                ForEach(Array(self.replyLines.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .lineLimit(1)
                        .fixedSize()
                        .font(.custom("replylines", size: 25, relativeTo: .callout))
                        .foregroundColor(Color("replyLines"))
                        .overlay(
                            Text(
                                chatService.postsToHighlight.contains(postId) && selectedPostDepth - 1 == index && index > 0 ? String(character) : ""
                            )
                                .lineLimit(1)
                                .fixedSize()
                                .font(.custom("replylines", size: 25, relativeTo: .callout))
                                .foregroundColor(Color.red)
                        )
                }
            }
            
            // Rarely a post category is set on a reply
            if self.postCategory == "nws" {
                Text("nws")
                    .bold()
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.systemRed))
            } else if self.postCategory == "stupid" {
                Text("stupid")
                    .bold()
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.systemGreen))
            } else if self.postCategory == "informative" {
                Text("inf")
                    .bold()
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.systemBlue))
            }
            
            // One line preview of post body, blue if it is the users post
            Text(appService.blockedAuthors.contains(self.postAuthor) ? "[blocked]" : self.postBody.getPreview)
                .fontWeight(postStrength != nil ? PostDecorator().postWeight[postStrength!] : .regular)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.callout)
                .foregroundColor(self.username == self.postAuthor.lowercased() ? Color(UIColor.systemTeal) : (colorScheme == .dark ? Color(UIColor.white) : Color(UIColor.black)))
                .opacity(postStrength != nil ? postStrength! : 0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
         
            // Maybe show post author
            if appService.blockedAuthors.contains(self.postAuthor) && appService.displayPostAuthor {
                Text("[blocked]")
                    .font(.footnote)
                    .bold()
                    .foregroundColor(Color(UIColor.systemOrange))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .fixedSize()
            }
            else if appService.displayPostAuthor {
                AuthorNameView(name: postAuthor, postId: postId, op: self.op)
            }
            
            // Tags/Lols
            LolView(lols: postLols, postId: postId)
        }
    }
}
