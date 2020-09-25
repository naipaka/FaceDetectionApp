//
//  CameraViewModel.swift
//  FaceDetectionApp
//
//  Created by 小林遼太 on 2020/09/23.
//  Copyright © 2020 小林遼太. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa
import Vision

protocol CameraViewModelInput {
    var captureOutputTrigger: PublishSubject<CMSampleBuffer> { get }
}

protocol CameraViewModelOutput {
    var detectionResultImage: PublishSubject<UIImage?> { get }
    var navigationItemRightButtonTitle: Observable<String> { get }
}

protocol CameraViewModelType {
    var input: CameraViewModelInput { get }
    var output: CameraViewModelOutput { get }
}

final class CameraViewModel: Injectable, CameraViewModelType, CameraViewModelInput, CameraViewModelOutput {

    typealias Dependency = Void

    var input: CameraViewModelInput { return self }
    var output: CameraViewModelOutput { return self }

    // MARK: - input
    var captureOutputTrigger = PublishSubject<CMSampleBuffer>()

    // MARK: - output
    var detectionResultImage = PublishSubject<UIImage?>()
    var navigationItemRightButtonTitle: Observable<String>

    private var sampleBuffer: CMSampleBuffer?
    private var outputType: OutputType = .rect
    private var catCgImage: CGImage?

    private let disposeBag = DisposeBag()

    // MARK: - injectable
    init(with dependency: Void) {
        navigationItemRightButtonTitle = Observable.just("Switch")

        guard let imagePath = Bundle.main.path(forResource: "CatFace", ofType: "png") else { return }
        guard let image = UIImage(contentsOfFile: imagePath) else { return }
        catCgImage = image.cgImage

        captureOutputTrigger
            .map { [weak self] in self?.sampleBuffer = $0 }
            .flatMapLatest { return self.getFaceObservations() }
            .map { [weak self] in return self?.getDetectionResultImage($0) }
            .bind(to: detectionResultImage)
            .disposed(by: disposeBag)
    }

    private func getFaceObservations() -> Observable<[VNFaceObservation]> {
        return Observable<[VNFaceObservation]>.create({ [weak self] observer in
            if let sampleBuffer = self?.sampleBuffer,
                let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let request = VNDetectFaceRectanglesRequest { (request, error) in
                    guard let results = request.results as? [VNFaceObservation] else {
                        observer.onNext([])
                        return
                    }
                    observer.onNext(results)
                }
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
                try? handler.perform([request])
            }
            return Disposables.create()
        })
    }

    private func getDetectionResultImage(_ faceObservations: [VNFaceObservation]) -> UIImage? {
        guard let sampleBuffer = sampleBuffer else { return nil }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        guard let pixelBufferBaseAddres = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }

        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue))

        let newContext = CGContext(
            data: pixelBufferBaseAddres,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(imageBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
        )

        faceObservations
            .compactMap { $0.boundingBox.converted(to: CGSize(width: width, height: height)) }
            .forEach{ draw(newContext, in: $0) }

        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        guard let imageRef = newContext?.makeImage() else { return nil }

        return UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImage.Orientation.up)
    }

    private func draw(_ context: CGContext?, in rect: CGRect) {
        switch outputType {
        case .rect:
            context?.setLineWidth(4.0)
            context?.setStrokeColor(UIColor.green.cgColor)
            context?.stroke(rect)
        case .cat:
            guard let catCgImage = catCgImage else { return }
            context?.draw(catCgImage, in: rect)
        case .mosaic:
            guard let catCgImage = catCgImage else { return }
            context?.draw(catCgImage, in: rect)
        }
    }
}
