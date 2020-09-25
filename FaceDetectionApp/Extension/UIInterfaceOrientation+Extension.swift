//
//  UIInterfaceOrientation+Extension.swift
//  FaceDetectionApp
//
//  Created by 小林遼太 on 2020/09/24.
//  Copyright © 2020 小林遼太. All rights reserved.
//

import UIKit
import AVFoundation

extension UIInterfaceOrientation {
    func convertToVideoOrientation() -> AVCaptureVideoOrientation? {
        switch self {
        case .unknown:
            return nil
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        @unknown default:
            return nil
        }
    }
}
