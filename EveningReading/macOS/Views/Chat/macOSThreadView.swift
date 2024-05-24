//
//  macOSThreadView.swift
//  EveningReading (macOS)
//
//  Created by Chris Hodge on 6/11/21.
//

import SwiftUI

struct macOSThreadView: View {
    @EnvironmentObject var appService: AppService
    @EnvironmentObject var chatService: ChatService
    
    @Binding var threadId: Int
    
    @State private var rootPostCategory: String = "ontopic"
    @State private var rootPostAuthor: String = ""
    @State private var rootPostBody: String = ""
    @State private var rootPostRichText = [RichTextBlock]()
    @State private var rootPostDate: String = "2020-08-14T21:05:00Z"
    @State private var rootPostLols: [ChatLols] = [ChatLols]()
    @State private var contributed: Bool = false
    @State private var replyCount: Int = 0
    
    @State private var postList = [ChatPosts]()
    @State private var postStrength = [Int: Double]()
    @State private var replyLines = [Int: String]()
    
    @State private var selectedPost = 0
    @State private var selectedPostRichText = [RichTextBlock]()
    
    @State private var showingHideAlert = false
    @State private var hideThread = false
    
    @State private var selectedPostDepth = 0
    
    private func getThreadData() {
        let threads = chatService.threads.filter({ return appService.threadFilters.contains($0.posts.filter({ return $0.parentId == 0 })[0].category) && !appService.collapsedThreads.contains($0.posts.filter({ return $0.parentId == 0 })[0].threadId)})
        
        if let thread = threads.filter({ return $0.threadId == self.threadId }).first {
            self.contributed = PostDecorator.checkParticipatedStatus(thread: thread, author: self.rootPostAuthor)
            if let rootPost = thread.posts.filter({ return $0.parentId == 0 }).first {
                self.rootPostCategory = rootPost.category
                self.rootPostAuthor = rootPost.author
                self.rootPostBody = rootPost.body
                self.rootPostRichText = RichTextBuilder.getRichText(postBody: rootPost.body.replaceGTRT)
                self.rootPostDate = rootPost.date
                self.rootPostLols = rootPost.lols
            }
            self.replyCount = thread.posts.count - 1
        }
    }
    
    private func getPostList(parentId: Int) {
        if let thread = chatService.threads.filter({ return $0.threadId == self.threadId }).first {
            // Replies to post
            let replies = thread.posts.filter({ return $0.parentId == parentId }).sorted(by: { $0.id < $1.id })
            
            // Font strength for recent posts
            postStrength = PostDecorator.getPostStrength(thread: thread)
            
            // Get replies to this post
            for post in replies {
                self.replyLines[post.id] = ReplyLineBuilder.getLines(post: post, thread: thread)
                postList.append(post)
                getPostList(parentId: post.id)
            }
        }
    }
    
    private func setSelectedPost(_ postIndex: Int) {
        chatService.activeParentId = postList[postIndex].id
        selectedPost = postList[postIndex].id
        chatService.scrollTargetChat = postList[postIndex].id        
        chatService.postsToHighlight.removeAll()
    }
    
    private func getChildren(parentId: Int) {
        let children = self.postList.filter({ $0.parentId == parentId })
        for child in children {
            chatService.postsToHighlight.append(child.id)
            getChildren(parentId: child.id)
        }
    }
    
    private func showNextReply() {
        if postList.count > 0 {
            if self.selectedPost == 0 {
                setSelectedPost(0)
            } else {
                for i in 0..<self.postList.count {
                    if self.selectedPost == self.postList[i].id {
                        if i + 1 < self.postList.count {
                            setSelectedPost(i + 1)
                        } else {
                            setSelectedPost(0)
                        }
                        break
                    }
                }
            }
        }
    }
    
    private func showPreviousReply() {
        if postList.count > 0 {
            if self.selectedPost == 0 {
                setSelectedPost(postList.count - 1)
            } else {
                for i in 0..<self.postList.count {
                    if self.selectedPost == self.postList[i].id {
                        if i - 1 > -1 {
                            setSelectedPost(i - 1)
                        } else {
                            setSelectedPost(postList.count - 1)
                        }
                        break
                    }
                }
            }
        }
    }
    
    private func updateThread() {
        self.hideThread = false
        getThreadData()
        postList = [ChatPosts]()
        postStrength = [Int: Double]()
        replyLines = [Int: String]()
        getPostList(parentId: self.threadId)
        selectedPost = 0
        chatService.scrollTargetChat = 0
    }
    
    private func finishedRefreshing(_ value: Bool) {
        if value {
            getThreadData()
            postList = [ChatPosts]()
            postStrength = [Int: Double]()
            replyLines = [Int: String]()
            getPostList(parentId: self.threadId)
            chatService.showingRefreshThreadSpinner = false
            chatService.scrollTargetChat = 0
        }
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            
            if hideThread || appService.collapsedThreads.contains(self.threadId) {
                
                Text("No thread selected.")
                    .font(.body)
                    .bold()
                    .foregroundColor(Color("NoDataLabel"))
                    .padding(.top, 10)
                
            } else {
            
                // Root post
                VStack (alignment: .leading) {
                    HStack {
                        AuthorNameView(name: self.rootPostAuthor, postId: self.threadId)
                        
                        ContributedView(contributed: self.contributed)

                        HStack {
                            Button(action: {
                                // previous
                                showPreviousReply()
                            }, label: {
                                EmptyView()
                            })
                            .buttonStyle(.plain)
                            .keyboardShortcut("a", modifiers: [])

                            Button(action: {
                                // next
                                showNextReply()
                            }, label: {
                                EmptyView()
                            })
                            .buttonStyle(.plain)
                            .keyboardShortcut("z", modifiers: [])
                        }
                        
                        Button(action: {
                            // refresh
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                                chatService.showingRefreshThreadSpinner = true
                                chatService.getThread()
                            }
                        }, label: {
                            Spacer().frame(width: 0)
                        })
                        .buttonStyle(.plain)
                        .keyboardShortcut("t", modifiers: [.command])
                        
                        Spacer()

                        Text("\(rootPostDate.getTimeRemaining()) left")
                            .foregroundColor(Color("NoDataLabel"))
                            .font(.body)
                            .help(rootPostDate.postTimestamp())
                        
                        Text("-")
                            .foregroundColor(Color("NoDataLabel"))
                        
                        ReplyCountView(replyCount: self.replyCount)
                            .padding(.trailing, 5)
                        
                        /*
                        Text(self.rootPostDate.getTimeAgo())
                            .foregroundColor(Color.gray)
                            .font(.body)
                        */

                        Image(systemName: "arrow.counterclockwise")
                            .imageScale(.large)
                            .onTapGesture(count: 1) {
                                chatService.showingRefreshThreadSpinner = true
                                chatService.getThread()
                            }
                        
                        macOSPostActionsView(name: self.rootPostAuthor, postId: self.threadId, showingHideThread: true)
                        
                        /*
                        Image(systemName: "eye.slash")
                            .imageScale(.large)
                            .onTapGesture(count: 1) {
                                self.showingHideAlert = true
                            }
                        .alert(isPresented: self.$showingHideAlert) {
                            Alert(title: Text("Hide thread?"), message: Text(""), primaryButton: .default(Text("Yes")) {
                                // collapse thread
                                appService.collapsedThreads.append(self.threadId)
                                chatService.activeThreadId = 0
                                self.hideThread = true
                            }, secondaryButton: .cancel() {
                                
                            })
                        }
                        */
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    
                    // Root post body
                    VStack (alignment: .leading) {
                        RichTextView(topBlocks: appService.blockedAuthors.contains(self.rootPostAuthor) ? RichTextBuilder.getRichText(postBody: "[blocked]") : self.rootPostRichText)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                    
                    if !appService.blockedAuthors.contains(self.rootPostAuthor) {
                        HStack {
                            LolView(lols: self.rootPostLols, expanded: true, postId: self.threadId)
                                .padding(.trailing, 1)

                            Spacer()
                            
                            if appService.isSignedIn {
                                macOSTagPostButton(postId: self.threadId)
                                Image(systemName: "link")
                                    .imageScale(.large)
                                    .onTapGesture(count: 1) {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString("https://www.shacknews.com/chatty?id=\(self.threadId)#item_\(self.threadId)", forType: .URL)
                                        chatService.didCopyLink = true
                                    }
                                Image(systemName: "arrowshape.turn.up.left")
                                    .imageScale(.large)
                                    .onTapGesture(count: 1) {
                                        chatService.newPostParentId = self.threadId
                                        chatService.newReplyAuthorName = self.rootPostAuthor
                                        chatService.showingNewPostSheet = true
                                    }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                    }
                    
                }
                .frame(maxWidth: .infinity)
                .background(Color("ThreadBubblePrimary"))
                .cornerRadius(10)
                .padding(.horizontal, 10)
                .padding(.top, 10)
            
                // Replies
                VStack(spacing: 0) {
                    // No replies yet
                    if postList.count < 1 {
                        HStack {
                            Spacer()
                            Text("No replies, be the first to post.")
                                .font(.body)
                                .bold()
                                .foregroundColor(Color("NoDataLabel"))
                            Spacer()
                        }
                    }
                    
                    // Post list
                    if chatService.hideReplies {
                        
                    } else {
                        ForEach(postList, id: \.id) { post in
                            HStack {
                                
                                // Reply expaned row
                                if chatService.activeParentId == post.id {
                                    VStack {
                                        macOSPostExpandedView(postId: .constant(post.id), postAuthor: .constant(post.author), replyLines: self.$replyLines[post.id], lols: .constant(post.lols), postText: self.$selectedPostRichText, postDateTime: .constant(post.date), op: .constant(self.rootPostAuthor))
                                    }
                                    .onAppear() {
                                        // Load Rich Text
                                        self.selectedPostRichText = RichTextBuilder.getRichText(postBody: post.body)
                                    }
                                }
                                
                                // Reply preview row
                                if chatService.activeParentId != post.id {
                                    HStack {
                                        macOSPostPreviewView(postId: .constant(post.id), postAuthor: .constant(post.author), replyLines: self.$replyLines[post.id], lols: .constant(post.lols), postText: .constant(post.body), postCategory: .constant(post.category), postStrength: .constant(postStrength[post.id]),
                                            op: .constant(self.rootPostAuthor), selectedPostDepth: $selectedPostDepth
                                        )}
                                    .contentShape(Rectangle())
                                    .onTapGesture(count: 1) {
                                        //withAnimation {
                                            chatService.activePostId = post.id
                                            chatService.activeParentId = post.id
                                            selectedPost = post.id
                                        
                                            selectedPostDepth = replyLines[post.id]?.count ?? 999
                                            chatService.postsToHighlight.removeAll()
                                            
                                            for siblingPost in postList.filter({ $0.parentId == post.parentId }) {
                                                chatService.postsToHighlight.append(siblingPost.id)
                                                getChildren(parentId: siblingPost.id)
                                            }
                                        //}
                                    }
                                }
                                
                            }
                            .id(post.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
        
        // Update view contents on when thread selected
        .onReceive(chatService.$activeThreadId) { _ in
            updateThread()
        }
        
        // When done refreshing (after posting or pull to refresh)
        .onReceive(chatService.$didGetThreadFinish) { value in
            finishedRefreshing(value)
        }
    }
}
