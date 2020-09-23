//
//  ViewController.swift
//  FaceDetectionApp
//
//  Created by 小林遼太 on 2020/09/23.
//  Copyright © 2020 小林遼太. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class HomeViewController: UIViewController, Injectable {

    typealias Dependency = HomeViewModel
    private var viewModel: HomeViewModel

    @IBOutlet weak var toCameraViewButton: UIButton!

    private let disposeBag = DisposeBag()

    // MARK: - Injectable
    required init(with dependency: HomeViewModel) {
        viewModel = dependency
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        onViewDidLoad()
    }

    // MARK: - private
    private func onViewDidLoad() {
        // input
        toCameraViewButton.rx.tap
            .subscribe(onNext: { [weak self] in
                let vc = CameraViewController()
                self?.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: disposeBag)

        // output
        viewModel.output.toCameraViewButtonTitle
            .bind(to: toCameraViewButton.rx.title())
            .disposed(by: disposeBag)
    }
}

