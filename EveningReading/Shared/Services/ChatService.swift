//
//  ChatService.swift
//  EveningReading
//
//  Created by Chris Hodge on 5/2/21.
//

import Foundation
import SwiftUI

// Service for chat related functionality
class ChatService: ObservableObject {
    
    private let service: ChatAPIService
    init(service: ChatAPIService) {
        self.service = service
    }

    @Published var threads: [ChatThread] = []
    @Published var activeThreadId: Int = 0
    
    @Published var activePostId: Int = 0
    @Published var activeParentId: Int = 0
    @Published var activePostDepth: Int = 0
    @Published var hideReplies = true
    
    @Published var postsToHighlight = [Int]()
    
    @Published var didSubmitPost = false

    @Published var didTagPost = false
    @Published var showingTagNotice = false
    @Published var taggingNoticeText = "Tagged!"
    
    @Published var showingFavoriteNotice = false
    
    @Published var didCopyLink = false
    @Published var showingCopiedNotice = false

    @Published var showingNewPostSheet = false
    @Published var newPostParentId = 0
    @Published var newReplyAuthorName = ""
    @Published var showingNewPostSpinner = false
    @Published var postingNewThread = false
    
    @Published var showingRefreshThreadSpinner = false

    @Published var didGetChatStart = false
    @Published var didSubmitNewThread = false
    @Published var didGetChatFinish = false
    @Published var didGetThreadStart = false
    @Published var didGetThreadFinish = false
    
    @Published var scrollTargetChat: Int?
    @Published var scrollTargetChatTop: Int?
    @Published var scrollTargetThread: Int?
    @Published var scrollTargetThreadTop: Int?
    
    @Published var shouldScrollThreadToTop = false
    
    @Published public var tagDelta = [Int: [String: Int]]()
    @Published public var tagRemovedDelta = [Int: [String: Int]]()

    @Published var showingCopyPostSheet = false
    @Published var copyPostText = ""
    @Published var templateA = ""
    @Published var templateB = ""

    // For pull to refresh
    @Published var gettingChat: Bool = false {
        didSet {
            if oldValue == false && gettingChat == true {
                #if os(iOS)
                // Delay long enough for the pull to refresh animation to complete...
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    self.getChat()
                }
                #endif
            }
        }
    }
    
    @Published var gettingThread: Bool = false {
        didSet {
            if oldValue == false && gettingThread == true {
                #if os(iOS)
                // Delay long enough for the pull to refresh animation to complete...
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    self.getThread()
                }
                #endif
            }
        }
    }
    
    func refreshChat() {
        activeThreadId = 0
        getChat()
    }

    // Get the entire chat
    func getChat() {
        self.didGetChatStart = true
        #if os(watchOS)
        self.threads = []
        self.gettingChat = true
        #endif
        #if os(OSX)
        self.threads = []
        self.gettingChat = true
        #endif
        getChatFromAPI() { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let threads):
                    self?.threads = threads
                    self?.tagDelta = [Int: [String: Int]]()
                    self?.tagRemovedDelta = [Int: [String: Int]]()
                case .failure:
                    self?.threads = []
                    
                }
                DispatchQueue.main.async {
                    self?.didGetChatFinish = true
                    self?.gettingChat = false
                }
            }
        }
    }
    
    public func getChatFromAPI(handler: @escaping (Result<[ChatThread], Error>) -> Void) {
        let decoder: JSONDecoder = .init()
        
        let sessionConfig = URLSessionConfiguration.default
        #if os(iOS)
        sessionConfig.waitsForConnectivity = false
        sessionConfig.timeoutIntervalForResource = 10.0
        #endif
        let shortSession = URLSession(configuration: sessionConfig)
        
        guard
            let urlComponents = URLComponents(string: "https://winchatty.com/v2/getChatty")
            else { preconditionFailure("Can't create url components...") }

        guard
            let url = urlComponents.url
            else { preconditionFailure("Can't create url from url components...") }

        shortSession.dataTask(with: url) { data, _, error in
            if let error = error {
                handler(.failure(error))
            } else {
                do {
                    let data = data ?? Data()
                    let response = try decoder.decode(Chat.self, from: data)
                    handler(.success(response.threads))
                } catch {
                    handler(.failure(error))
                }
            }
        }.resume()
    }
    
    // Get a thread
    func getThread() {
        self.didGetThreadStart = true
        getThreadFromAPI(threadId: self.activeThreadId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let threads):
                    let threadId = self?.activeThreadId ?? 0
                    if let row = self?.threads.firstIndex(where: {$0.threadId == threadId}) {
                        if threads[0].posts.count > 0 {
                            self?.threads[row] = threads[0]
                        }
                    }
                case .failure:
                    print("failure to getThread")
                }
                DispatchQueue.main.async {
                    self?.tagDelta.removeValue(forKey: self?.activeThreadId ?? 0)
                    self?.tagRemovedDelta.removeValue(forKey: self?.activeThreadId ?? 0)
                    self?.didGetThreadFinish = true
                    self?.gettingThread = false
                }
            }
        }
    }
    
    public func getThreadFromAPI(threadId: Int, handler: @escaping (Result<[ChatThread], Error>) -> Void) {
        let decoder: JSONDecoder = .init()
        let sessionConfig = URLSessionConfiguration.default
        #if os(iOS)
        sessionConfig.waitsForConnectivity = false
        sessionConfig.timeoutIntervalForResource = 10.0
        #endif
        let shortSession = URLSession(configuration: sessionConfig)
        
        guard
            var urlComponents = URLComponents(string: "https://winchatty.com/v2/getThread")
            else { preconditionFailure("Can't create url components...") }

        urlComponents.queryItems = [
            URLQueryItem(name: "id", value: (String(threadId)))
        ]

        guard
            let url = urlComponents.url
            else { preconditionFailure("Can't create url from url components...") }

        shortSession.dataTask(with: url) { data, _, error in
            if let error = error {
                handler(.failure(error))
            } else {
                do {
                    let data = data ?? Data()
                    let response = try decoder.decode(Chat.self, from: data)
                    handler(.success(response.threads))
                } catch {
                    handler(.failure(error))
                }
            }
        }.resume()
    }
    
    // Tag post
    @Published private(set) var tagResponse: TagReponse = TagReponse(status: "0", data: nil, message: "")
    func tag(postId: Int, tag: String, untag: String) {
        tagPost(postId: postId, tag: tag, untag: untag) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.tagResponse = response
                case .failure:
                    self?.tagResponse = TagReponse(status: "0", data: nil, message: "")
                }
            }
        }
    }
    
    public func tagPost(postId: Int, tag: String, untag: String, handler: @escaping (Result<TagReponse, Error>) -> Void) {
        if let lolKey = Bundle.main.infoDictionary?["LOL_KEY"] as? String {
            let session: URLSession = .shared
            let decoder: JSONDecoder = .init()
            
            let username = UserHelper.getUserName()
            
            guard
                var urlComponents = URLComponents(string: "https://www.shacknews.com/api2/api-index.php")
                else { preconditionFailure("Can't create url components...") }
            
            urlComponents.queryItems = [
                URLQueryItem(name: "action2", value: "ext_create_tag_via_api"),
                URLQueryItem(name: "untag", value: untag),
                URLQueryItem(name: "secret", value: lolKey),
                URLQueryItem(name: "tag", value: tag),
                URLQueryItem(name: "user", value: username),
                URLQueryItem(name: "id", value: (String(postId)))
            ]

            guard
                let url = urlComponents.url
                else { preconditionFailure("Can't create url from url components...") }

            session.dataTask(with: url) { data, _, error in
                if let error = error {
                    handler(.failure(error))
                } else {
                    do {
                        let data = data ?? Data()
                        let response = try decoder.decode(TagReponse.self, from: data)
                        handler(.success(response))
                    } catch {
                        handler(.failure(error))
                    }
                }
            }.resume()
            
        } else {
            
        }
    }
    
    // Submit post
    @Published var submitPostSuccessMessage: String = ""
    @Published var submitPostErrorMessage: String = ""
    @Published private(set) var submitPostResponse: SubmitPostResponseContainer = SubmitPostResponseContainer(success: SubmitPostReponse(result: ""), fail: SubmitPostError(error: false, code: "ERR_NONE", message: "No error."))
    func submitPost(postBody: String, postId: Int) {
        self.didSubmitPost = true
        service.submitPost(postBody: postBody, postId: postId) { [weak self] result in
            DispatchQueue.main.async {
                self?.submitPostSuccessMessage = ""
                self?.submitPostErrorMessage = ""

                switch result {
                case .success(let response):
                    self?.submitPostResponse = response
                    if response.success.result == "success" {
                        self?.submitPostSuccessMessage = "Post submitted successfully."
                        self?.submitPostErrorMessage = ""
                    } else {
                        self?.submitPostSuccessMessage = ""
                        self?.submitPostErrorMessage = response.fail.message
                    }
                case .failure:
                    self?.submitPostResponse = SubmitPostResponseContainer(success: SubmitPostReponse(result: "failure"), fail: SubmitPostError(error: true, code: "ERR_SERVER", message: "Error posting."))
                    self?.submitPostSuccessMessage = ""
                    self?.submitPostErrorMessage = "Error posting.  Please try again."
                }
            }
        }
    }
    
    // Taggers / Lolers
    @Published var raters: [Raters] = []
    func getRaters(postId: Int, completionSuccess: @escaping ()->(), completionFail: @escaping ()->()) {
        getRaters(postId: postId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let ratersResponse):
                    self?.raters = ratersResponse.data
                    completionSuccess()
                case .failure:
                    self?.raters = []
                    completionFail()
                }
            }
        }
    }
    
    public func getRaters(postId: Int, handler: @escaping (Result<RatersResponse, Error>) -> Void) {
        let session: URLSession = .shared
        let decoder: JSONDecoder = .init()
        
        guard
            var urlComponents = URLComponents(string: "https://www.shacknews.com/api2/api-index.php")
            else { preconditionFailure("Can't create url components...") }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "action2", value: "ext_get_all_raters"),
            URLQueryItem(name: "tag", value: "all"),
            URLQueryItem(name: "ids[]", value: (String(postId)))
        ]

        guard
            let url = urlComponents.url
            else { preconditionFailure("Can't create url from url components...") }

        session.dataTask(with: url) { data, _, error in
            if let error = error {
                handler(.failure(error))
            } else {
                do {
                    let data = data ?? Data()
                    var dataAsString = String(data: data, encoding: .utf8)
                    dataAsString = "{\"raters\": " + (dataAsString ?? "") + "}"
                    let articleData: Data? = dataAsString?.data(using: .utf8)
                    let response = try decoder.decode(RatersWrapper.self, from: articleData ?? Data())
                    handler(.success(response.raters ))
                } catch {
                    handler(.failure(error))
                }
            }
        }.resume()
    }
    
    // Search
    @Published private(set) var searchResults: [SearchChatPosts] = []
    func search(terms: String, author: String, parentAuthor: String, completion: @escaping ()->()) {
        searchWithAPI(terms: terms, author: author, parentAuthor: parentAuthor) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let foundPosts):
                    print("search results: \(foundPosts.count)")
                    self?.searchResults = foundPosts
                    completion()
                case .failure:
                    print("search failure")
                    self?.searchResults = []
                }
            }
        }
    }
    
    public func searchWithAPI(terms: String, author: String, parentAuthor: String, handler: @escaping (Result<[SearchChatPosts], Error>) -> Void) {
        let session: URLSession = .shared
        let decoder: JSONDecoder = .init()
        
        guard
            var urlComponents = URLComponents(string: "https://winchatty.com/v2/search")
            else { preconditionFailure("Can't create url components...") }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "35"),
            URLQueryItem(name: "oldestFirst", value: "false")
        ]
        
        if terms != "" {
            urlComponents.queryItems?.append(URLQueryItem(name: "terms", value: terms))
        }
        if author != "" {
            urlComponents.queryItems?.append(URLQueryItem(name: "author", value: author))
        }
        if parentAuthor != "" {
            urlComponents.queryItems?.append(URLQueryItem(name: "parentAuthor", value: parentAuthor))
        }
        
        guard
            let url = urlComponents.url
            else { preconditionFailure("Can't create url from url components...") }

        session.dataTask(with: url) { data, _, error in
            if let error = error {
                handler(.failure(error))
            } else {
                do {
                    let data = data ?? Data()
                    let response = try decoder.decode(SearchChat.self, from: data)
                    handler(.success(response.posts))
                } catch {
                    handler(.failure(error))
                }
            }
        }.resume()
    }

    // Load any thread
    @Published private(set) var searchedThreads: [ChatThread] = []
    func getThreadByPost(postId: Int, completion: @escaping ()->()) {
        getThreadByPostFromAPI(postId: postId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let foundThreads):
                    self?.searchedThreads = foundThreads
                    completion()
                case .failure:
                    self?.searchedThreads = []
                }
            }
        }
    }
    
    public func getThreadByPostFromAPI(postId: Int, handler: @escaping (Result<[ChatThread], Error>) -> Void) {
        let session: URLSession = .shared
        let decoder: JSONDecoder = .init()
        
        guard
            let urlComponents = URLComponents(string: "https://winchatty.com/v2/getThread?id=\(postId)")
            else { preconditionFailure("Can't create url components...") }

        guard
            let url = urlComponents.url
            else { preconditionFailure("Can't create url from url components...") }

        session.dataTask(with: url) { data, _, error in
            if let error = error {
                handler(.failure(error))
            } else {
                do {
                    let data = data ?? Data()
                    let response = try decoder.decode(Chat.self, from: data)
                    handler(.success(response.threads))
                } catch {
                    handler(.failure(error))
                }
            }
        }.resume()
    }

    #if os(iOS)
    func uploadImageToImgur(image: UIImage, postBody: String, complete: @escaping (Bool, String) -> ()) {
        if let imgurKey = Bundle.main.infoDictionary?["IMGUR_KEY"] as? String {
            var resizedImage = image
            let imageSize = image.getSizeIn(.megabyte)
            
            if imageSize > 9.0 {
                resizedImage = image.resized(withPercentage: 0.5) ?? image
            }

            getBase64Image(image: resizedImage) { base64Image in
                let boundary = "Boundary-\(UUID().uuidString)"

                var request = URLRequest(url: URL(string: "https://api.imgur.com/3/image")!)
                request.addValue("Client-ID \(imgurKey)", forHTTPHeaderField: "Authorization")
                request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

                request.httpMethod = "POST"

                var body = ""
                body += "--\(boundary)\r\n"
                body += "Content-Disposition:form-data; name=\"image\""
                body += "\r\n\r\n\(base64Image ?? "")\r\n"
                body += "--\(boundary)--\r\n"
                let postData = body.data(using: .utf8)

                request.httpBody = postData
                request.timeoutInterval = 60

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if error != nil {
                        complete(false, postBody)
                        return
                    }
                    guard let response = response as? HTTPURLResponse,
                          (200...299).contains(response.statusCode) else {
                        complete(false, postBody)
                        return
                    }
                    if let mimeType = response.mimeType, mimeType == "application/json", let data = data, let _ = String(data: data, encoding: .utf8) {
                        let parsedResult: [String: AnyObject]
                        do {
                            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
                            if let dataJson = parsedResult["data"] as? [String: Any] {
                                let newPostBody = postBody + "\n\(dataJson["link"] as? String ?? "[Error Uploading Image]")"
                                complete(true, newPostBody)
                            }
                        } catch {
                            complete(false, postBody)
                        }
                    }
                }.resume()
            }
            
        } else {
            complete(false, postBody)
        }
    }
    
    func getBase64Image(image: UIImage, complete: @escaping (String?) -> ()) {
        DispatchQueue.main.async {
            let imageData = image.pngData()
            let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters)
            complete(base64Image)
        }
    }
    #endif
}

class ChatAPIService {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }
    
    public func submitPost(postBody: String, postId: Int, handler: @escaping (Result<SubmitPostResponseContainer, Error>) -> Void) {
        //print("returning from submitPost for post \(postId) with text: \(postBody)")
        //let resp = SubmitPostResponseContainer(success: SubmitPostReponse(result: "success"), fail: SubmitPostError(error: false, code: "ERR_NONE", message: "No error."))
        //let resp = SubmitPostResponseContainer(success: SubmitPostReponse(result: "failure"), fail: SubmitPostError(error: true, code: "47", message: "test failure"))
        //handler(.success(resp))
        //return
        
        let username = UserHelper.getUserName()
        let password = UserHelper.getUserPassword()
        
        print("post submitted to server... post \(postId)")
        
        let newPostUrl = URL(string: "https://winchatty.com/v2/postComment")!
        var components = URLComponents(url: newPostUrl, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "username", value: username.replacingOccurrences(of: "+", with: "%2B").replacingOccurrences(of: "&", with: "%26")),
            URLQueryItem(name: "password", value: password.replacingOccurrences(of: "+", with: "%2B").replacingOccurrences(of: "&", with: "%26")),
            URLQueryItem(name: "parentId", value: String(postId)),
            URLQueryItem(name: "text", value: postBody.replacingOccurrences(of: "+", with: "%2B").replacingOccurrences(of: "&", with: "%26"))
        ]
        // .replacingOccurrences(of: "#", with: "%23")
        
        guard
            let query = components.url!.query
            else { preconditionFailure("Can't create url components...") }
        
        var request = URLRequest(url: newPostUrl)
        request.httpMethod = "POST"
        request.httpBody = components.query?.data(using: .utf8) //Data(query.utf8)

        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                handler(.failure(error!))
                return
            }
            guard let data = data else {
                handler(.failure(error!))
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    var didProcessResponse = false
                    
                    do {
                        let successResponse = try self.decoder.decode(SubmitPostReponse.self, from: data)
                        let resp = SubmitPostResponseContainer(success: SubmitPostReponse(result: "success"), fail: SubmitPostError(error: false, code: "ERR_NONE", message: "No error."))
                        didProcessResponse = true
                        handler(.success(resp))
                    } catch {
                        // ChattyService submitPost - successResponse fail
                    }

                    if !didProcessResponse {
                        do {
                            let failResponse = try self.decoder.decode(SubmitPostError.self, from: data)
                            let resp = SubmitPostResponseContainer(success: SubmitPostReponse(result: "failure"), fail: SubmitPostError(error: true, code: failResponse.code, message: failResponse.message))
                            didProcessResponse = true
                            handler(.success(resp))
                        } catch {
                            // ChattyService submitPost - failResponse fail
                        }
                    }
                }
            } catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
}
