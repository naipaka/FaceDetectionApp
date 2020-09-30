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
    private var pickerView = UIPickerView()

    private var videoOrientation: AVCaptureVideoOrientation?
    private var avCaptureSession = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDidDisappear()
    }

    // MARK: - private
    private func onViewDidLoad() {
        setupUI()
        bind()
        setupVideoProcessing(withPosition: .back)
    }

    private func onViewDidDisappear() {
        avCaptureSession.stopRunning()
    }

    private func setupUI() {
        // UINavigationItem
        navigationItem.setRightBarButton(UIBarButtonItem(), animated: true)
    }

    private func bind() {
        // input
        capturedOutputStream
            .bind(to: viewModel.input.captureOutputTrigger)
            .disposed(by: disposeBag)

        navigationItem.rightBarButtonItem?.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.switchCaptureDevicePosition()
            })
            .disposed(by: disposeBag)

        let tapGesture = UITapGestureRecognizer()
        tapGesture.rx.event
            .bind(to: viewModel.input.tappedImageTrigger)
            .disposed(by: disposeBag)
        detectionResultImageView.isUserInteractionEnabled = true
        detectionResultImageView.addGestureRecognizer(tapGesture)

        // output
        viewModel.output.detectionResultImage
            .bind(to: detectionResultImageView.rx.image)
            .disposed(by: disposeBag)

        viewModel.output.navigationItemRightButtonTitle
            .bind(to: (navigationItem.rightBarButtonItem?.rx.title)!)
            .disposed(by: disposeBag)
    }

    private func setupVideoProcessing(withPosition position: AVCaptureDevice.Position) {
        // videoOrientation
        DispatchQueue.main.async {
            self.videoOrientation = self.appOrientation.convertToVideoOrientation()
        }

        avCaptureSession.sessionPreset = .photo

        // AVCaptureSession#addInput
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
        guard let videoDevice = videoDevice else { return }
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        avCaptureSession.addInput(deviceInput)

        // AVCaptureSession#addOutput
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.setSampleBufferDelegate(self, queue: .global())
        avCaptureSession.addOutput(videoDataOutput)

        avCaptureSession.startRunning()
    }

    private func switchCaptureDevicePosition() {
        avCaptureSession.stopRunning()
        avCaptureSession.inputs.forEach { avCaptureSession.removeInput($0) }
        avCaptureSession.outputs.forEach { avCaptureSession.removeOutput($0) }

        setupVideoProcessing(withPosition: (videoDevice?.position == .front ? .back : .front))
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        capturedOutputStream.onNext(sampleBuffer)
        guard let videoOrientation = videoOrientation else { return }
        connection.videoOrientation = videoOrientation
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.main.async {
            self.videoOrientation = self.appOrientation.convertToVideoOrientation()
        }
    }
}
