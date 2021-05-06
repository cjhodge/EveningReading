//
//  TrendingCard.swift
//  EveningReading
//
//  Created by Chris Hodge on 5/2/21.
//

import SwiftUI

struct TrendingCard: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appSessionStore: AppSessionStore
    @Binding var thread: ChatThread
    @State private var postPreview: String = ""
    @State private var postDate: String = ""
    @State private var postCount: Int = 0
    @State private var postAuthor: String = ""
    @State private var percentRemaining: CGFloat = 0.0
    
    func getCardData() {
        // get root post
        let post = self.thread.posts.filter({ return $0.parentId == 0 })
        
        if post.count > 0 {
            self.postPreview = post[0].body.getPreview
            self.postDate = post[0].date.getTimeRemaining()
            self.postCount = self.thread.posts.count - 1
            self.postAuthor = post[0].author
            self.percentRemaining = post[0].date.getPercentRemaining()
        }
    }
    
    var body: some View {
        return VStack(alignment: .leading) {
            HStack {
                Spacer()
                VStack {
                    ZStack {
                        VStack {
                            HStack {
                                Image("QuoteBegin")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .imageScale(.small)
                                    .frame(width: 20)
                                    .foregroundColor(Color("DoubleQuote"))
                                Spacer()
                            }
                            Spacer()
                        }
                        VStack {
                            Text(postPreview)
                                .font(postPreview.count > 140 ? .caption : .subheadline)
                                .foregroundColor(.white)
                                .padding(.top, 15)
                                .padding(.bottom, 5)
                        }
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image("QuoteEnd")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .imageScale(.small)
                                    .frame(width: 10)
                                    .foregroundColor(Color("DoubleQuote"))
                            }
                        }
                    }
                    .frame(height: 140)
                    .padding(20)
                }
                .background(Color("TrendingCardSecondaryBackground"))
                .cornerRadius(30)
                .frame(height: 180)
                .frame(minWidth: 270)
                .frame(maxWidth: 270)
                .padding(.top, 30)
                .padding(.horizontal, 20)
                Spacer()
            }
            
            HStack {
                Color("TrendingCardFill")
                    .frame(width: self.percentRemaining, height: 6)
                    .padding(.leading, 0)
                    .cornerRadius(3)
                    .frame(width: 235, height: 6, alignment: .leading)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(3)
                    .padding()
                    .frame(height: 24)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

            }
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            
            Text("Expires: \(self.postDate)")
                .font(.subheadline)
                .foregroundColor(Color.white).opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
            
            Text("Replies: \(self.postCount)")
                .font(.subheadline)
                .foregroundColor(Color.white).opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
            
            HStack {
                Text("Author: \(self.postAuthor)")
                    .font(.subheadline)
                    .foregroundColor(Color.white).opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 10)
                Spacer()
                Image(systemName: "eye.slash")
                    .foregroundColor(Color.white).opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
            }
            
            Spacer().frame(height: 20)
        }
        .onAppear(perform: getCardData)
        .background(Color("TrendingCardPrimaryBackground"))
        .cornerRadius(30)
        .frame(minWidth: 300)
        .frame(maxWidth: 300)
        .frame(minHeight: 360)
        .shadow(color: Color("TrendingCardShadow"), radius: 16, x: 0, y: 16)
    }
}

struct TrendingCard_Previews: PreviewProvider {
    static var previews: some View {
        TrendingCard(thread: .constant(chatData.threads[0]))
    }
}