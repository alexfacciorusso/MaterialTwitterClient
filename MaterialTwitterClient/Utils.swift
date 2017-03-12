//
//  Utils.swift
//  MaterialTwitterClient
//
//  Created by Alex Facciorusso on 11/03/17.
//  Copyright © 2017 Alex Facciorusso. All rights reserved.
//

import UIKit

extension UILabel {
    func setTwitterText(fromString text: String) {
        let tweetText = NSString(string: text)
        let tweetAttributedText = NSMutableAttributedString(string: text)
        
        text.components(separatedBy: .whitespacesAndNewlines).forEach {
            if $0.hasPrefix("#") || $0.hasPrefix("@") {
                tweetAttributedText.addAttribute(NSForegroundColorAttributeName, value: self.tintColor, range: tweetText.range(of: $0))
            }
        }
        self.attributedText = tweetAttributedText

    }
}
