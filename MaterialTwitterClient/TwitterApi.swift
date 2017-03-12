//
//  TwitterApi.swift
//  MaterialTwitterClient
//
//  Created by Alex Facciorusso on 09/03/17.
//  Copyright © 2017 Alex Facciorusso. All rights reserved.
//

import Foundation
import SwifteriOS
import RxSwift
import Nuke
import NukeToucanPlugin

class TwitterApi {
    static let sharedInstance = { return TwitterApi() }()
    
    private let twitterConsumerKey = "YOUR_TWITTER_CONSUMER_KEY"
    private let twitterConsumerSecret = "YOUR_TWITTER_CONSUMER_SECRET"

    var isAuthenticated = false
    private let swifter: Swifter
    
    private init() {
        self.swifter = Swifter(consumerKey: twitterConsumerKey, consumerSecret: twitterConsumerSecret, appOnly: true)
    }
    
    func authorizeApp() -> Observable<Void> {
        return Observable.create { obs in
            print("Authorizing app…")
            self.swifter.authorizeAppOnly(success: { _ in
                print("Twitter authorization success.")
                self.isAuthenticated = true
                obs.onCompleted()
            }, failure: { err in
                print("Twitter authorization error.", err)
                obs.onError(err)
            })
            return Disposables.create()
        }
    }
    
    func searchForTweets(usingQuery query: String) -> Observable<[Tweet]> {
        return Observable.create { obs in
            self.swifter.searchTweet(using: query, count: 100, success: { json, _ in
                guard let tweetsJson = json.array else {
                    obs.onNext([])
                    obs.onCompleted()
                    return
                }
                let tweets = tweetsJson.map { it -> Tweet in
                    var avatar: URL? = nil
                    if let avatarStr = it["user"]["profile_image_url_https"].string {
                        avatar = URL(string: avatarStr)
                    }
                    return Tweet(id: it["id"].integer!, name: it["user"]["name"].string!, screenName: it["user"]["screen_name"].string!, avatar: avatar, text: it["text"].string!)
                }
                obs.onNext(tweets)
                obs.onCompleted()
            }, failure: { err in
                obs.onError(err)
            })
            return Disposables.create()
            }.observeOn(MainScheduler.instance)
    }
}
