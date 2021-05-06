//
//  ReplyCountView.swift
//  EveningReading (iOS)
//
//  Created by Chris Hodge on 5/3/21.
//

import SwiftUI

struct ReplyCountView: View {
    @Binding var replyCount: Int
    
    var body: some View {
        #if os(iOS)
            Text("\(self.replyCount)")
                .font(.footnote)
                .foregroundColor(Color(UIColor.systemGray)) +
            Text(self.replyCount == 1 ? " Reply" : " Replies")
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.systemGray))
        #endif
        #if os(OSX)
            if self.replyCount > 0 {
                Text("\(self.replyCount)")
                    .font(.body) +
                Text(self.replyCount == 1 ? " Reply" : " Replies")
                    .font(.body)
            } else {
                EmptyView()
            }
        #endif
        #if os(watchOS)
            Text("(\(self.replyCount))")
                .font(.footnote)
                .foregroundColor(Color.gray)
        #endif
    }
}

struct ReplyCountView_Previews: PreviewProvider {
    static var previews: some View {
        ReplyCountView(replyCount: .constant(33))
    }
}