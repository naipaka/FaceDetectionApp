//
//  HomeViewModel.swift
//  FaceDetectionApp
//
//  Created by 小林遼太 on 2020/09/23.
//  Copyright © 2020 小林遼太. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol HomeViewModelInput {}

protocol HomeViewModelOutput {
    var toCameraViewButtonTitle: Observable<String> { get }
}

protocol HomeViewModelType {
    var input: HomeViewModelInput { get }
    var output: HomeViewModelOutput { get }
}

final class HomeViewModel: Injectable, HomeViewModelType, HomeViewModelInput, HomeViewModelOutput {

    typealias Dependency = Void

    var input: HomeViewModelInput { return self }
    var output: HomeViewModelOutput { return self }

    // MARK: - output
    var toCameraViewButtonTitle: Observable<String>

    // MARK: - injectable
    init(with dependency: Void) {
        self.toCameraViewButtonTitle = Observable.just("Activate camera")
    }
}
