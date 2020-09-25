//
//  CGRect+Extension.swift
//  FaceDetectionApp
//
//  Created by 小林遼太 on 2020/09/24.
//  Copyright © 2020 小林遼太. All rights reserved.
//

import AVFoundation

extension CGRect {
    func converted(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.minX * size.width,
            y: self.minY * size.height,
            width: self.width * size.width,
            height: self.height * size.height
        )
    }
}
