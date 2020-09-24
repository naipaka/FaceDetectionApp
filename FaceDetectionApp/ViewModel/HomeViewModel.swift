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

protocol HomeViewModelInput {
    var didTapToCameraViewButtonTrigger: PublishSubject<Void> { get }
}

protocol HomeViewModelOutput {
    var toCameraViewButtonTitle: Observable<String> { get }
    var navigateToCameraViewStream: PublishSubject<Void> { get }
}

protocol HomeViewModelType {
    var input: HomeViewModelInput { get }
    var output: HomeViewModelOutput { get }
}

final class HomeViewModel: Injectable, HomeViewModelType, HomeViewModelInput, HomeViewModelOutput {

    typealias Dependency = Void

    var input: HomeViewModelInput { return self }
    var output: HomeViewModelOutput { return self }

    // MARK: - input
    var didTapToCameraViewButtonTrigger = PublishSubject<Void>()

    // MARK: - output
    var toCameraViewButtonTitle: Observable<String>
    var navigateToCameraViewStream = PublishSubject<Void>()

    private let disposeBag = DisposeBag()

    // MARK: - injectable
    init(with dependency: Void) {
        toCameraViewButtonTitle = Observable.just("Activate camera")

        didTapToCameraViewButtonTrigger
            .bind(to: navigateToCameraViewStream)
            .disposed(by: disposeBag)
    }
}
