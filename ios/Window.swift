//
//  Window.swift
//  Runner
//
//  Created by Amorn Apichattanakul on 24/6/21.
//

import Foundation
import UIKit

private let blurViewTag = 999

extension UIWindow {

    func blur() {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = frame
        blurEffectView.tag = blurViewTag
        addSubview(blurEffectView)
    }

    func unBlur() {
        viewWithTag(blurViewTag)?.removeFromSuperview()
    }

}

