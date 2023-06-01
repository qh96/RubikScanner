//
//  CameraView.swift
//  RubikScanner
//
//  Created by Hao Qin on 6/1/23.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject var camera = CameraViewModel()

    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea()
        }
        .onAppear(perform: camera.check)
        .alert(isPresented: $camera.showCameraRequiredAlert) {
            Alert(title: Text("Camera Access Required"), message: Text("This app needs access to the camera to work. Please grant access in Settings."), dismissButton: .default(Text("OK")))
        }
    }
}

class CameraViewModel: NSObject, ObservableObject {
    @Published var showCameraRequiredAlert = false
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()

    override init() {
        super.init()
        setup()
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)

    }

    private func setup() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            fatalError("No back camera found")
        }

        let videoInput = try! AVCaptureDeviceInput(device: videoDevice)

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            fatalError("Cannot add video input")
        }

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("Cannot add video output")
        }

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing.queue"))
    }

    func check() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                startSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted { DispatchQueue.main.async { self.startSession() } }
                }
            default:
                showCameraRequiredAlert = true
            }
        }

    private func startSession() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Here is where we'll process each frame with OpenCV...
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let previewView = PreviewView()
        previewView.videoPreviewLayer.session = camera.captureSession
        return previewView
    }

    func updateUIView(_ uiView: UIView, context: Context) { }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
