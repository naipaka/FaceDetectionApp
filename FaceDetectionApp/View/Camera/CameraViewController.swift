//
//  CameraViewController.swift
//  FaceDetectionApp
//
//  Created by 小林遼太 on 2020/09/23.
//  Copyright © 2020 小林遼太. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

class CameraViewController: UIViewController, Injectable {

    typealias Dependency = CameraViewModel
    private var viewModel: CameraViewModelType

    @IBOutlet weak var detectionResultImageView: UIImageView!

    private let avCaptureSession = AVCaptureSession()
    private let capturedOutputStream = PublishSubject<CMSampleBuffer>()

    private let disposeBag = DisposeBag()

    // MARK: - Injectable
    required init(with dependency: CameraViewModel) {
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onViewDidAppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDidDisappear()
    }

    // MARK: - private
    private func onViewDidLoad() {
        bind()
        setupVideoProcessing()
    }

    private func onViewDidAppear() {
        avCaptureSession.startRunning()
    }

    private func onViewDidDisappear() {
        avCaptureSession.stopRunning()
    }

    private func setupVideoProcessing() {
        avCaptureSession.sessionPreset = .photo

        // addInput
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else { return }
        avCaptureSession.addInput(deviceInput)

        // addOutput
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.setSampleBufferDelegate(self, queue: .global())
        avCaptureSession.addOutput(videoDataOutput)
    }

    private func bind() {
        // input
        capturedOutputStream
            .bind(to: viewModel.input.captureOutputTrigger)
            .disposed(by: disposeBag)

        // output
        viewModel.output.detectionResultImage
            .bind(to: detectionResultImageView.rx.image)
            .disposed(by: disposeBag)
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        capturedOutputStream.onNext(sampleBuffer)
    }
}
