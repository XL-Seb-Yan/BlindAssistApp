//
//  Untitled.swift
//  BlindAssistAI
//
//  Created by Jason Huang on 16/11/2026.
//
import AVFoundation
import CoreImage
import CoreVideo
import Foundation
import UIKit

// Camera state seen by SwiftUI is confined to the main actor.
@MainActor
final class LiveCameraManager {
    var onFrame: ((UIImage) -> Void)?
    var onError: ((String) -> Void)?

    private var shouldRun = false

    private lazy var worker = CameraWorker(
        onData: { [weak self] jpegData in
            Task { @MainActor [weak self] in
                guard let self,
                      self.shouldRun,
                      let image = UIImage(data: jpegData) else { return }
                self.onFrame?(image)
            }
        },
        onError: { [weak self] message in
            Task { @MainActor [weak self] in
                guard let self, self.shouldRun else { return }
                self.onError?(message)
            }
        }
    )

    var session: AVCaptureSession { worker.session }

    func start() {
        shouldRun = true
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            worker.start()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] allowed in
                Task { @MainActor [weak self] in
                    guard let self, self.shouldRun else { return }
                    if allowed {
                        self.worker.start()
                    } else {
                        self.onError?("未取得相机权限，请在设置中允许使用相机。")
                    }
                }
            }
        default:
            onError?("相机权限已被拒绝，请前往设置开启权限。")
        }
    }

    func requestNextFrame() {
        guard shouldRun else { return }
        worker.requestNextFrame()
    }

    func stop() {
        shouldRun = false
        worker.stop()
    }
}

// The session's mutable state lives exclusively on sessionQueue.
nonisolated private final class CameraWorker: @unchecked Sendable {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "blindassist.camera.session")
    private let frameQueue = DispatchQueue(label: "blindassist.camera.frames")
    private let sampler: VideoFrameSampler
    private let onError: @Sendable (String) -> Void
    private var configured = false  // Only read/written on sessionQueue.

    init(onData: @escaping @Sendable (Data) -> Void,
         onError: @escaping @Sendable (String) -> Void) {
        self.onError = onError
        self.sampler = VideoFrameSampler(queue: frameQueue, onData: onData)
    }

    func start() {
        sessionQueue.async { [self] in
            if !configured && !configureSession() { return }
            if !session.isRunning { session.startRunning() }
        }
    }

    func stop() {
        sampler.cancelPendingFrame()
        sessionQueue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func requestNextFrame() {
        sampler.requestOneFrame()
    }

    private func configureSession() -> Bool {
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .back
        ), let input = try? AVCaptureDeviceInput(device: camera) else {
            onError("无法打开后置摄像头。")
            return false
        }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]

        session.beginConfiguration()
        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        } else {
            session.sessionPreset = .medium
        }

        guard session.canAddInput(input) else {
            session.commitConfiguration()
            onError("无法配置摄像头输入。")
            return false
        }
        session.addInput(input)

        guard session.canAddOutput(output) else {
            session.removeInput(input)
            session.commitConfiguration()
            onError("无法配置摄像头视频输出。")
            return false
        }
        session.addOutput(output)
        output.setSampleBufferDelegate(sampler, queue: frameQueue)
        session.commitConfiguration()

        // This classroom MVP supports a portrait-oriented camera experience.
        if let connection = output.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        configured = true
        return true
    }
}

// One explicitly requested frame at a time. No frame backlog.
nonisolated private final class VideoFrameSampler:
    NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

    private let queue: DispatchQueue
    private let onData: @Sendable (Data) -> Void
    private let context = CIContext()
    private var wantsFrame = false  // Only accessed on queue.

    init(queue: DispatchQueue, onData: @escaping @Sendable (Data) -> Void) {
        self.queue = queue
        self.onData = onData
    }

    func requestOneFrame() {
        queue.async { [weak self] in self?.wantsFrame = true }
    }

    func cancelPendingFrame() {
        queue.async { [weak self] in self?.wantsFrame = false }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard wantsFrame,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent),
              let data = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.65)
        else { return }

        wantsFrame = false
        onData(data)
    }
}

