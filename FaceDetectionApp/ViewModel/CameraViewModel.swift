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

    var sampleBuffer: CMSampleBuffer?
    let disposeBag = DisposeBag()

    // MARK: - injectable
    init(with dependency: Void) {
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

        guard let newContext = CGContext(
            data: pixelBufferBaseAddres,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(imageBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
            ) else
        {
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }

        let imageSize = CGSize(width: width, height: height)
        let faseRects = faceObservations.compactMap {
            getUnfoldRect(normalizedRect: $0.boundingBox, targetSize: imageSize)
        }
        faseRects.forEach{ self.drawRect($0, context: newContext) }

        guard let imageRef = newContext.makeImage() else { return nil }

        return UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImage.Orientation.right)
    }

    private func getUnfoldRect(normalizedRect: CGRect, targetSize: CGSize) -> CGRect {
        return CGRect(
            x: normalizedRect.minX * targetSize.width,
            y: normalizedRect.minY * targetSize.height,
            width: normalizedRect.width * targetSize.width,
            height: normalizedRect.height * targetSize.height
        )
    }

    private func drawRect(_ rect: CGRect, context: CGContext) {
        context.setLineWidth(4.0)
        context.setStrokeColor(UIColor.green.cgColor)
        context.stroke(rect)
    }
}
