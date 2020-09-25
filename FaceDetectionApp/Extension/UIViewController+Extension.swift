//
//  UIInterfaceOrientation+Extension.swift
//  FaceDetectionApp
//
//  Created by 小林遼太 on 2020/09/24.
//  Copyright © 2020 小林遼太. All rights reserved.
//

import UIKit

extension UIViewController {
    var appOrientation: UIInterfaceOrientation {
        if #available(iOS 13, *)  {
            return self.view.window?.windowScene?.interfaceOrientation ?? .unknown
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }
}
