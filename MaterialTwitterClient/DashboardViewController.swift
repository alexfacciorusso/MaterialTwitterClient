//
//  ViewController.swift
//  MaterialTwitterClient
//
//  Created by Alex Facciorusso on 09/03/17.
//  Copyright © 2017 Alex Facciorusso. All rights reserved.
//

import UIKit
import MaterialComponents
import Nuke
import NukeToucanPlugin
import PureLayout

class DashboardViewController: MDCCollectionViewController {
    let reusableCellItem = "cellItem"
    let tweetSelectedSegueId = "TweetSelected"
    
    let appBar = MDCAppBar()
    let activityIndicator = MDCActivityIndicator.newAutoLayout()
    
    var tweets: [Tweet] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "#MaterialDesign"
        addChildViewController(appBar.headerViewController)
        
        // Register cell class.
        self.collectionView?.register(MDCCollectionViewTextCell.self,
                                      forCellWithReuseIdentifier: reusableCellItem)
        
        appBar.headerViewController.headerView.backgroundColor = MaterialTwitterClient.colorPrimary
        appBar.headerViewController.headerView.trackingScrollView = self.collectionView
        appBar.navigationBar.tintColor = UIColor.white
        appBar.navigationBar.titleTextAttributes =
            [ NSForegroundColorAttributeName: UIColor.white ]
        
        _ = TwitterApi.sharedInstance.authorizeApp().subscribe(
            onError: { err in print(err) }, onCompleted: searchTweets)
        
        appBar.addSubviewsToParent()
        
        view.addSubview(activityIndicator)
        activityIndicator.sizeToFit()
        activityIndicator.autoCenterInSuperview()
        activityIndicator.indicatorMode = .indeterminate
        activityIndicator.cycleColors = [MaterialTwitterClient.colorAccent]
        activityIndicator.radius = 16
        activityIndicator.startAnimating()
    }
    
    func searchTweets() {
        _ = TwitterApi.sharedInstance.searchForTweets(usingQuery: "#MaterialDesign")
            .subscribe { on in
                switch on {
                case .next(let tweets):
                    self.tweets = tweets
                case .error(let err):
                    self.activityIndicator.stopAnimating()
                    print(err)
                case .completed:
                    self.activityIndicator.stopAnimating()
                    self.collectionView?.reloadData()
                }
        }
    }
        
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// CollectionView stuff
extension DashboardViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
        return MDCCellDefaultThreeLineHeight
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tweets.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //performSegue(withIdentifier: tweetSelectedSegueId, sender: self)
        let controller = TweetDetailViewController(fromTweet: tweets[indexPath.row])
        present(controller, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusableCellItem, for: indexPath)
        
        let currentTweet = tweets[indexPath.row]
        if let mdCell = cell as? MDCCollectionViewTextCell {
            mdCell.detailTextLabel?.text = "\(currentTweet.name) • @\(currentTweet.screenName)"
            mdCell.textLabel?.numberOfLines = 2
            mdCell.textLabel?.tintColor = MaterialTwitterClient.colorAccent
            mdCell.textLabel?.setTwitterText(fromString: currentTweet.text)
            
            if let avatar = currentTweet.avatar {
                let request = Nuke.Request(url: avatar).processed(key: "Avatar") {
                    return $0.resize(CGSize(width: 40, height: 40), fitMode: .clip)
                        .maskWithEllipse()
                }
                Nuke.loadImage(with: request, into: mdCell) { [weak mdCell] response, _ in
                    guard let imageView = mdCell?.imageView else {return}
                    imageView.image = response.value
                    mdCell?.setNeedsLayout()
                }
            }
        }
        
        return cell
    }
}

// ScrollView stuff
extension DashboardViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == appBar.headerViewController.headerView.trackingScrollView {
            appBar.headerViewController.headerView.trackingScrollDidScroll()
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == appBar.headerViewController.headerView.trackingScrollView {
            appBar.headerViewController.headerView.trackingScrollDidEndDecelerating()
        }
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == appBar.headerViewController.headerView.trackingScrollView {
            let headerView = appBar.headerViewController.headerView
            headerView.trackingScrollDidEndDraggingWillDecelerate(decelerate)
        }
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView == appBar.headerViewController.headerView.trackingScrollView {
            let headerView = appBar.headerViewController.headerView
            headerView.trackingScrollWillEndDragging(withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
    }
}
