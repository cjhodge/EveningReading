//
//  RichTextView.swift
//  EveningReading (iOS)
//
//  Created by Chris Hodge on 5/6/21.
//
//  This repo helped me a lot: https://github.com/JohnHeitmann/SwiftUI-Rich-Text-Demo Thanks!
//

import Foundation
import SwiftUI

/*
extension Text {

    /// Creates an instance that wraps an `Image`, suitable for concatenating
    /// with other `Text`
    @available(iOS 14.0, OSX 10.16, tvOS 14.0, watchOS 7.0, *)
    public init(_ image: Image)
}
*/

struct TextAttributes: OptionSet, Hashable {
    let rawValue: Int
    
    static let bold    = TextAttributes(rawValue: 1 << 0)
    static let italic  = TextAttributes(rawValue: 1 << 1)
    static let heading = TextAttributes(rawValue: 1 << 2)
    static let normal = TextAttributes(rawValue: 1 << 3)
    static let blue = TextAttributes(rawValue: 1 << 4)
    static let green = TextAttributes(rawValue: 1 << 5)
    static let orange = TextAttributes(rawValue: 1 << 6)
    static let yellow = TextAttributes(rawValue: 1 << 7)
    static let red = TextAttributes(rawValue: 1 << 8)
    static let pink = TextAttributes(rawValue: 1 << 9)
    static let olive = TextAttributes(rawValue: 1 << 10)
    static let lime = TextAttributes(rawValue: 1 << 11)
    static let strike = TextAttributes(rawValue: 1 << 12)
    static let sample = TextAttributes(rawValue: 1 << 13)
    static let quote = TextAttributes(rawValue: 1 << 14)
    static let code = TextAttributes(rawValue: 1 << 15)
    static let underline = TextAttributes(rawValue: 1 << 16)
}

enum RichTextBlock: Hashable {
    case plainTextBlock([InlineText])
    case quote([RichTextBlock])
    case spoiler([SpoilerBlock])
    case link([LinkBlock])
    case spoilerlink([SpoilerLinkBlock])
}

struct SpoilerView: View {
    @Environment(\.colorScheme) var colorScheme
    var spoilerText: String
    @State private var spoilerClicked = false
    
    #if os(iOS)
    var body: some View {
        Text(spoilerText)
            .background(self.spoilerClicked ? Color.clear : Color("Spoiler"))
            .foregroundColor(self.spoilerClicked ? Color(UIColor.label) : Color("Spoiler"))
            .onTapGesture(count: 1) {
                self.spoilerClicked = true
            }
    }
    #endif
    
    #if os(OSX)
    var body: some View {
        Text(spoilerText)
            .font(.body)
            .background(self.spoilerClicked ? Color.clear : Color("Spoiler"))
            .foregroundColor(self.spoilerClicked ? Color(NSColor.labelColor) : Color("Spoiler"))
            .onTapGesture(count: 1) {
                self.spoilerClicked = true
            }
    }
    #endif
    
    #if os(watchOS)
    var body: some View {
        Text(spoilerText)
            .font(.footnote)
            .background(self.spoilerClicked ? Color.clear : Color("Spoiler"))
            .foregroundColor(self.spoilerClicked ? Color.primary : Color("Spoiler"))
            .onTapGesture(count: 1) {
                self.spoilerClicked = true
            }
    }
    #endif
}

struct LinkView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appService: AppService
    @EnvironmentObject var chatService: ChatService
    var hyperlink: String = ""
    var description: String = ""
    
    @State private var showingSafariSheet = false
    @State private var hyperlinkUrl: URL?
    
    @State private var hyperlinkUrlStr: String?
    @State private var showingLinkWebView = false
    
    @State private var linkForeground = Color("LinkText")
    
    #if os(iOS)
    var body: some View {
        
        LinkViewerSheet(hyperlinkUrl: self.$hyperlinkUrlStr, showingWebView: self.$showingLinkWebView)
    
        HStack(alignment: .bottom, spacing: 0) {
            Text(self.description)
                .underline()
                .foregroundColor(linkForeground)
                //.foregroundColor(colorScheme == .dark ? Color(UIColor.systemTeal) : Color(UIColor.black))
                .onTapGesture(count: 1) {
                    // Fixes an iOS 17 bug
                    if (colorScheme == .dark) {
                        linkForeground = Color(UIColor.systemTeal)
                    } else {
                        linkForeground = Color(UIColor.black)
                    }
                    
                    // YouTube
                    if appService.useYoutubeApp && (self.hyperlink.starts(with: "https://www.youtube.com/") || self.hyperlink.starts(with: "https://youtube.com/") || self.hyperlink.starts(with: "https://youtu.be/")) {
                        let url = URL(string: self.hyperlink.replacingOccurrences(of: "https", with: "youtube"))!
                        if !UIApplication.shared.canOpenURL(url)  {
                            //self.hyperlinkUrlStr = self.hyperlink
                            //self.showingLinkWebView = true
                            if let url = URL(string: self.hyperlink) {
                                self.hyperlinkUrl = url
                                self.showingSafariSheet = true
                                appService.showingSafariSheet = true
                            }
                        } else {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                    // Shack link
                    else if self.hyperlink.starts(with: "https://www.shacknews.com/chatty?id=") || self.hyperlink.starts(with: "http://www.shacknews.com/chatty?id=")
                    {
                        if let url = URL(string: self.hyperlink) {
                            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                            if let queryItems = components?.queryItems {
                                for queryItem in queryItems {
                                    if queryItem.name == "id" {
                                        appService.setLink(postId: queryItem.value ?? "")
                                    }
                                }
                            }
                        }
                    }
                    // Chattypics
                    else if self.hyperlink.starts(with: "https://www.chattypics.com") || self.hyperlink.starts(with: "http://www.chattypics.com") || self.hyperlink.starts(with: "https://chattypics.com") || self.hyperlink.starts(with: "http://chattypics.com")
                    {
                        // Use Better Safari View
                        if let url = URL(string: self.hyperlink) {
                            self.hyperlinkUrl = url
                            self.showingSafariSheet = true
                            appService.showingSafariSheet = true
                        }
                    }
                    // Apple
                    else if self.hyperlink.starts(with: "https://apps.apple.com")
                    {
                        // Open Directly
                        let appleLink = self.hyperlink.replacingOccurrences(of: "https", with: "itms-apps")
                        if let url = URL(string: appleLink) {
                            UIApplication.shared.open(url)
                        }
                    }
                    // Everything else - i.e. a random link in a thread
                    else {
                        // Use LinkViewerSheet
                        self.hyperlinkUrlStr = self.hyperlink
                        self.showingLinkWebView = true
                    }
                }
            
            if appService.showLinkCopyButton {
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = self.hyperlink
                    chatService.showingCopiedNotice = true
                }) {
                    Image(systemName: "doc.on.doc")
                        .imageScale(.small)
                }
            }
        }
        
        // Better Safari View
        //.safariView(isPresented: self.$showingSafariSheet) {
        .sheet(isPresented: self.$showingSafariSheet) {
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(Color(UIColor.systemFill))
                    .frame(width: 40, height: 5)
                    .cornerRadius(3)
                    .opacity(0.5)
                    .padding(.top, 8)
                SafariView(
                    url: URL(string: self.hyperlink)!,
                    configuration: SafariView.Configuration(
                        entersReaderIfAvailable: false,
                        barCollapsingEnabled: true
                    )
                )
                .preferredBarAccentColor(.clear)
                .preferredControlAccentColor(.accentColor)
                .dismissButtonStyle(.done)
            }
        }
        
        // If push notification tapped
        .onReceive(PushNotificationsService.shared.$notificationData) { value in
            if value != nil {
                self.showingSafariSheet = false
                appService.showingSafariSheet = false
            }
        }
        
    }
    #endif
    
    #if os(OSX)
    var body: some View {
        Text(self.description)
            .font(.body)
            .underline()
            .foregroundColor(colorScheme == .dark ? Color(NSColor.systemTeal) : Color(NSColor.black))
            .onTapGesture(count: 1) {
                if let url = URL(string: self.hyperlink) {
                    self.hyperlinkUrlStr = self.hyperlink
                    self.showingLinkWebView = true
                    //NSWorkspace.shared.open(url)
                }
            }
            .popover(isPresented: self.$showingLinkWebView) {
                macOSLinkViewerSheet(mesgURL: self.hyperlink)
            }
    }
    #endif
    
    #if os(watchOS)
    var body: some View {
        Link(self.description, destination: URL(string: self.hyperlink)!)
    }
    #endif
}

struct RichTextView: View {
    let topBlocks: [RichTextBlock]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(topBlocks, id: \.self) { block in
                TextBlockView(block: block)
            }
        }
    }
}

struct TextBlockView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let block: RichTextBlock
    
    var body: some View {
        VStack(alignment: .leading) { // Dummy wrapper view to appease the compiler
            switch block {
            case .plainTextBlock(let text):
                renderInlineText(text)
            case .quote(let quote):
                renderQuote(quote)
            case .spoiler(let spoiler):
                renderSpoiler(spoiler)
            case .link(let link):
                renderLink(link)
            case .spoilerlink(let spoilerlink):
                renderSpoilerLink(spoilerlink)
            }
        }
    }
    
    func renderLink(_ link: [LinkBlock]) -> some View {
        return VStack(alignment: .leading) {
            ForEach(link, id: \.self) { l in
                LinkView(hyperlink: l.hyperlink, description: l.description)
            }
        }
    }
    
    func renderSpoiler(_ spoiler: [SpoilerBlock]) -> some View {
        return VStack(alignment: .leading) {
            ForEach(spoiler, id: \.self) { s in
                SpoilerView(spoilerText: s.text)
            }
        }
    }
    
    func renderSpoilerLink(_ spoilerlink: [SpoilerLinkBlock]) -> some View {
        return VStack(alignment: .leading) {
            ForEach(spoilerlink, id: \.self) { l in
                LinkView(hyperlink: l.hyperlink, description: l.description)
            }
        }
    }
    
    func renderInlineText(_ text: [InlineText]) -> some View {
        return text.map {t in
            var inlineTextView: Text = Text(t.text)
            
            #if os(macOS)
            inlineTextView = inlineTextView.font(.body)
            #endif
            
            if t.attributes.contains(.bold) {
                inlineTextView = inlineTextView.bold()
            }
            if t.attributes.contains(.italic) {
                inlineTextView = inlineTextView.italic()
            }
            if t.attributes.contains(.underline) {
                inlineTextView = inlineTextView.underline()
            }
            if t.attributes.contains(.heading) {
                inlineTextView = inlineTextView.font(.headline)
            }
            if t.attributes.contains(.blue) {
                #if os(iOS)
                inlineTextView = inlineTextView.foregroundColor(Color(UIColor.systemBlue))
                #endif
                #if os(OSX)
                inlineTextView = inlineTextView.foregroundColor(Color(NSColor.systemBlue))
                #endif
                #if os(watchOS)
                inlineTextView = inlineTextView.foregroundColor(Color.blue)
                #endif
            }
            if t.attributes.contains(.green) {
                #if os(iOS)
                inlineTextView = inlineTextView.foregroundColor(Color(UIColor.systemGreen))
                #endif
                #if os(OSX)
                inlineTextView = inlineTextView.foregroundColor(Color(NSColor.systemGreen))
                #endif
                #if os(watchOS)
                inlineTextView = inlineTextView.foregroundColor(Color.green)
                #endif
            }
            if t.attributes.contains(.orange) {
                #if os(iOS)
                inlineTextView = inlineTextView.foregroundColor(Color(UIColor.systemOrange))
                #endif
                #if os(OSX)
                inlineTextView = inlineTextView.foregroundColor(Color(NSColor.systemOrange))
                #endif
                #if os(watchOS)
                inlineTextView = inlineTextView.foregroundColor(Color.orange)
                #endif
            }
            if t.attributes.contains(.yellow) {
                #if os(iOS)
                inlineTextView = inlineTextView.foregroundColor(Color("YellowText"))
                // inlineTextView = inlineTextView.foregroundColor(colorScheme == .dark ?  Color(UIColor.systemYellow) : Color("LightSchemeYellow"))
                #endif
                #if os(OSX)
                inlineTextView = inlineTextView.foregroundColor(Color(NSColor.systemYellow))
                #endif
                #if os(watchOS)
                inlineTextView = inlineTextView.foregroundColor(Color.yellow)
                #endif
            }
            if t.attributes.contains(.red) {
                #if os(iOS)
                inlineTextView = inlineTextView.foregroundColor(Color(UIColor.systemRed))
                #endif
                #if os(OSX)
                inlineTextView = inlineTextView.foregroundColor(Color(NSColor.systemRed))
                #endif
                #if os(watchOS)
                inlineTextView = inlineTextView.foregroundColor(Color.red)
                #endif
            }
            if t.attributes.contains(.pink) {
                inlineTextView = inlineTextView.foregroundColor(Color("PinkText"))
            }
            if t.attributes.contains(.olive) {
                inlineTextView = inlineTextView.foregroundColor(Color("OliveText"))
            }
            if t.attributes.contains(.lime) {
                inlineTextView = inlineTextView.foregroundColor(Color("LimeText"))
            }
            if t.attributes.contains(.strike) {
                inlineTextView = inlineTextView.strikethrough()
            }
            if t.attributes.contains(.quote) {
                #if os(watchOS)
                inlineTextView = inlineTextView.font(.custom("Georgia", size: 17, relativeTo: .footnote))
                #else
                inlineTextView = inlineTextView.font(.custom("Georgia", size: 17, relativeTo: .body))
                #endif
            }
            if t.attributes.contains(.sample) {
                #if os(watchOS)
                inlineTextView = inlineTextView.font(.custom("Georgia", size: 17, relativeTo: .footnote))
                #else
                inlineTextView = inlineTextView.font(.custom("San Francisco", size: 14, relativeTo: .body))
                #endif
            }
            if t.attributes.contains(.code) {
                #if os(watchOS)
                inlineTextView = inlineTextView.font(.custom("Georgia", size: 17, relativeTo: .footnote))
                #else
                inlineTextView = inlineTextView.font(.custom("Menlo Regular", size: 14, relativeTo: .body))
                #endif
            }
            #if os(watchOS)
            if !t.attributes.contains(.quote) && !t.attributes.contains(.sample) && !t.attributes.contains(.code) {
                inlineTextView = inlineTextView.font(.footnote)
            }
            #endif
            return inlineTextView
        }.reduce(Text(""), +)
        #if os(OSX)
        .textSelection(.enabled)
        #endif
    }

    func renderQuote(_ quote: [RichTextBlock]) -> some View {
        return VStack(alignment: .leading) {
            ForEach(quote, id: \.self) {q in
                TextBlockView(block: q)
            }
        }
        .padding()
        .border(Color.gray, width: 1)
        .padding()
    }
    
}

class RichTextBuilder {
    
    static func getRichText(postBody: String) -> [RichTextBlock] {
        var richText = [RichTextBlock]()
        
        // Regex matching html/tags
        let postBodyMarkup = "<body>" + postBody.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "<br /><a", with: "<a").replacingOccurrences(of: "</a><br /><br />", with: "</a>\n").replacingOccurrences(of: "<br />", with: "\n") + "</body>"
        let rangeTotal = NSRange(location: 0, length: postBodyMarkup.utf16.count)
        let regexTags = try! NSRegularExpression(pattern: #"<(?:"[^"]*"['"]*|'[^']*'['"]*|[^'">])+>"#)
        let matchesTags = regexTags.matches(in: postBodyMarkup, options: [], range: rangeTotal)
        var matchNum = 0
        var previousRange =  NSRange(location: 0, length: 0)
        
        // Find the content between the tags
        var resultsAll: [String] = []
        var resultsByType: [ShackPostMarkup] = []
        var attr: TextAttributes = [.normal]
        var lifo: [String] = []
        let _: [String] = matchesTags.map {
            let rangeTags = Range($0.range, in: postBodyMarkup)!
        
            if $0.range.lowerBound - previousRange.upperBound > 0 {
                let rangeContent = Range(NSRange(location: previousRange.upperBound, length: $0.range.lowerBound - previousRange.upperBound), in: postBodyMarkup)!
                resultsAll.append(String(postBodyMarkup[rangeContent]))
                resultsByType.append(ShackPostMarkup(postMarkup: String(postBodyMarkup[rangeContent]), postMarkupType: ShackMarkupType.content))
            }
            previousRange = $0.range
            matchNum += 1
            resultsAll.append(String(postBodyMarkup[rangeTags]))
            resultsByType.append(ShackPostMarkup(postMarkup: String(postBodyMarkup[rangeTags]), postMarkupType: ShackMarkupType.tag))
            return String(postBodyMarkup[rangeTags])
        }
        
        // Apply/unapply text formatting attributes
        var linkHref = ""
        var spoilerText = ""
        var hrefOpen = false
        var isSpoiler = false
        var isSpoilerLink = false
        var lineOfText = [InlineText]()
        for markup in resultsByType {
            
            enum Suit: String {
                case bold = "<b>"
                case Hearts = "♥"
                case Diamonds = "♦"
                case Clubs = "♣"
            }
            
            // Open tags
            if markup.postMarkupType == ShackMarkupType.tag {
                if markup.postMarkup == "<b>" {
                    if !attr.contains(TextAttributes.bold) {
                        attr.update(with: TextAttributes.bold)
                    }
                } else if markup.postMarkup == "</b>" {
                    if attr.contains(TextAttributes.bold) {
                        attr.remove(TextAttributes.bold)
                    }
                } else if markup.postMarkup == "<i>" {
                    if !attr.contains(TextAttributes.italic) {
                        attr.update(with: TextAttributes.italic)
                    }
                } else if markup.postMarkup == "</i>" {
                    if attr.contains(TextAttributes.italic) {
                        attr.remove(TextAttributes.italic)
                    }
                } else if markup.postMarkup == "<u>" {
                    if !attr.contains(TextAttributes.underline) {
                        attr.update(with: TextAttributes.underline)
                    }
                } else if markup.postMarkup == "</u>" {
                    if attr.contains(TextAttributes.underline) {
                        attr.remove(TextAttributes.underline)
                    }
                } else if markup.postMarkup == #"<pre class="jt_code">"# {
                    if !attr.contains(TextAttributes.code) {
                        attr.update(with: TextAttributes.code)
                    }
                } else if markup.postMarkup == "</pre>" {
                    if attr.contains(TextAttributes.code) {
                        attr.remove(TextAttributes.code)
                    }
                } else if markup.postMarkup == #"<span class="jt_blue">"# {
                    if !attr.contains(TextAttributes.blue) {
                        attr.update(with: TextAttributes.blue)
                    }
                    lifo.append("jt_blue")
                } else if markup.postMarkup.contains(#"<span class="jt_green">"#) {
                    if !attr.contains(TextAttributes.green) {
                        attr.update(with: TextAttributes.green)
                    }
                    lifo.append("jt_green")
                } else if markup.postMarkup.contains(#"<span class="jt_orange">"#) {
                    if !attr.contains(TextAttributes.orange) {
                        attr.update(with: TextAttributes.orange)
                    }
                    lifo.append("jt_orange")
                } else if markup.postMarkup.contains(#"<span class="jt_yellow">"#) {
                   if !attr.contains(TextAttributes.yellow) {
                       attr.update(with: TextAttributes.yellow)
                   }
                    lifo.append("jt_yellow")
                } else if markup.postMarkup.contains(#"<span class="jt_red">"#) {
                    if !attr.contains(TextAttributes.red) {
                        attr.update(with: TextAttributes.red)
                    }
                    lifo.append("jt_red")
                } else if markup.postMarkup.contains(#"<span class="jt_pink">"#) {
                    if !attr.contains(TextAttributes.pink) {
                        attr.update(with: TextAttributes.pink)
                    }
                    lifo.append("jt_pink")
                } else if markup.postMarkup.contains(#"<span class="jt_olive">"#) {
                    if !attr.contains(TextAttributes.olive) {
                        attr.update(with: TextAttributes.olive)
                    }
                    lifo.append("jt_olive")
                } else if markup.postMarkup.contains(#"<span class="jt_lime">"#) {
                    if !attr.contains(TextAttributes.lime) {
                        attr.update(with: TextAttributes.lime)
                    }
                    lifo.append("jt_lime")
                } else if markup.postMarkup.contains(#"<span class="jt_strike">"#) {
                    if !attr.contains(TextAttributes.strike) {
                        attr.update(with: TextAttributes.strike)
                    }
                    lifo.append("jt_strike")
                } else if markup.postMarkup.contains(#"<span class="jt_sample">"#) {
                    if !attr.contains(TextAttributes.sample) {
                        attr.update(with: TextAttributes.sample)
                    }
                    lifo.append("jt_sample")
                } else if markup.postMarkup.contains(#"<span class="jt_quote">"#) {
                    if !attr.contains(TextAttributes.quote) {
                        attr.update(with: TextAttributes.quote)
                    }
                    lifo.append("jt_quote")
                }
                else if markup.postMarkup.contains(#"<span class="jt_spoiler" onclick="this.className = '';">"#) {
                    lifo.append("jt_spoiler")
                    isSpoiler = true
                }
                else if markup.postMarkup.starts(with: #"<a target="_blank" href="https://www.shacknews.com/article/"#) {
                    linkHref = markup.postMarkup.replacingOccurrences(of: #"<a target="_blank" href=""#, with: "")
                    linkHref = linkHref.replacingOccurrences(of: #"">"#, with: "")
                    hrefOpen = true
                }
                else if markup.postMarkup.starts(with: #"<a href="https://www.shacknews.com/cortex/"#) {
                    linkHref = markup.postMarkup.replacingOccurrences(of: #"<a href=""#, with: "")
                    linkHref = linkHref.replacingOccurrences(of: #"" target="_blank">"#, with: "")
                    hrefOpen = true
                } else if markup.postMarkup.starts(with: #"<a target="_blank" rel="nofollow" href=""#) {
                    if isSpoiler {
                        isSpoilerLink = true
                        if spoilerText != "" {
                            // Spit out what's regular content
                            richText.append(.plainTextBlock(lineOfText))
                            lineOfText = [InlineText]()
                            // Now do the spoiler
                            richText.append(.spoiler([SpoilerBlock(text: spoilerText)]))
                        }
                        spoilerText = ""
                        var link = markup.postMarkup.replacingOccurrences(of: #"<a target="_blank" rel="nofollow" href=""#, with: "")
                        link = link.replacingOccurrences(of: #"">"#, with: "")
                        linkHref = link
                    }
                }
                
                // Close tags
                if markup.postMarkup == #"</span>"# {
                    if attr.contains(TextAttributes.blue) && lifo.last ?? "" == "jt_blue" {
                        attr.remove(TextAttributes.blue)
                        lifo.removeLast()
                    }
                    else if attr.contains(TextAttributes.green) && lifo.last ?? "" == "jt_green" {
                        attr.remove(TextAttributes.green)
                        lifo.removeLast()
                    }
                    else if attr.contains(TextAttributes.orange) && lifo.last ?? "" == "jt_orange" {
                        attr.remove(TextAttributes.orange)
                        lifo.removeLast()
                    }
                    else if attr.contains(TextAttributes.yellow) && lifo.last ?? "" == "jt_yellow" {
                        attr.remove(TextAttributes.yellow)
                        lifo.removeLast()
                    }
                    else if attr.contains(TextAttributes.red) && lifo.last ?? "" == "jt_red" {
                        attr.remove(TextAttributes.red)
                        lifo.removeLast()
                    }
                    else if attr.contains(TextAttributes.pink) && lifo.last ?? "" == "jt_pink" {
                        attr.remove(TextAttributes.pink)
                        lifo.removeLast()
                    }
                    else if attr.contains(TextAttributes.olive) && lifo.last ?? "" == "jt_olive" {
                        attr.remove(TextAttributes.olive)
                        lifo.removeLast()
                    }
                    else if attr.contains(TextAttributes.lime) && lifo.last ?? "" == "jt_lime" {
                        attr.remove(TextAttributes.lime)
                        lifo.removeLast()
                    }
                    else if attr.contains(TextAttributes.strike) && lifo.last ?? "" == "jt_strike" {
                        attr.remove(TextAttributes.strike)
                        lifo.removeLast()
                    }
                    else if attr.contains(TextAttributes.sample) && lifo.last ?? "" == "jt_sample" {
                        attr.remove(TextAttributes.sample)
                        lifo.removeLast()
                    }
                    else if attr.contains(TextAttributes.quote) && lifo.last ?? "" == "jt_quote" {
                        attr.remove(TextAttributes.quote)
                        lifo.removeLast()
                    }
                    else if lifo.last ?? "" == "jt_spoiler" {
                        lifo.removeLast()
                        isSpoiler = false
                        if spoilerText != "" {
                            // Spit out what's regular content
                            richText.append(.plainTextBlock(lineOfText))
                            lineOfText = [InlineText]()
                            // Now do the spoiler
                            richText.append(.spoiler([SpoilerBlock(text: spoilerText)]))
                        }
                        spoilerText = ""
                    }
                }
                
                // Anything could be within an href
                if  markup.postMarkup == "</a>" {
                    linkHref = ""
                    hrefOpen = false
                    isSpoilerLink = false
                }
            }

            // Append content, spoilers, links
            if markup.postMarkupType == ShackMarkupType.content {
                if !markup.postMarkup.hasPrefix("http") && !hrefOpen && !isSpoiler {
                    lineOfText.append(InlineText(text: String(markup.postMarkup).stringByDecodingHTMLEntities, attributes: attr))
                } else if isSpoilerLink {
                    richText.append(.link([LinkBlock(hyperlink: linkHref, description: markup.postMarkup)]))
                } else if isSpoiler {
                    // Still within spoiler tags
                    spoilerText += markup.postMarkup + " "
                } else if hrefOpen && linkHref != "" {
                    // Article or Cortex
                    richText.append(.plainTextBlock(lineOfText))
                    lineOfText = [InlineText]()
                    richText.append(.link([LinkBlock(hyperlink: linkHref, description: markup.postMarkup)]))
                }
            } else {
                if !isSpoiler && markup.postMarkup.starts(with: #"<a target="_blank" rel="nofollow" href=""#) {
                    // Random link in a post
                    richText.append(.plainTextBlock(lineOfText))
                    lineOfText = [InlineText]()
                    var link = markup.postMarkup.replacingOccurrences(of: #"<a target="_blank" rel="nofollow" href=""#, with: "")
                    link = link.replacingOccurrences(of: #"">"#, with: "")
                    richText.append(.link([LinkBlock(hyperlink: link, description: link)]))
                }
            }            
        }
        
        // Append remainder
        if lineOfText.count > 0 {
            richText.append(.plainTextBlock(lineOfText))
        }
                
        return richText
    }
}
