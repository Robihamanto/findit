//
//  CameraVC.swift
//  Findit
//
//  Created by Robihamanto on 04/03/18.
//  Copyright © 2018 Robihamanto. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState {
    case off
    case on
}

class CameraVC: UIViewController {
    
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var photoData: Data?
    var flashState: FlashState = .off
    var speechSynthesizer = AVSpeechSynthesizer()

    @IBOutlet weak var capturedImage: RoundedImageView!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var identificationLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var descriptionView: RoundedShadowView!
    @IBOutlet weak var spinnerActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechSynthesizer.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
    }
    
    @IBAction func flashButtonDidTap(_ sender: Any) {
        if flashState == .off {
            flashState = .on
            flashButton.setTitle("FLASH ON", for: .normal)
        } else {
            flashState = .off
            flashButton.setTitle("FLASH OFF", for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(cameraViewDidTap))
        tap.numberOfTapsRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput) {
                captureSession.addOutput(cameraOutput)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }

        } catch {
            debugPrint(error)
        }
    }
    
    func synthesizeSpeech(formString string: String) {
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speechUtterance)
    }
    
    @objc func cameraViewDidTap() {
        self.cameraView.isUserInteractionEnabled = false
        self.spinnerActivity.isHidden = false
        self.spinnerActivity.startAnimating()
        
        
        let settings = AVCapturePhotoSettings()
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if flashState == .off {
            settings.flashMode = .off
        } else {
            settings.flashMode = .on
        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultMethod(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else { return }
        
        for classification in results {
            if classification.confidence < 0.5 {
                let unknownObjectMessage = "I'm not sure what this is, please try again."
                identificationLabel.text = unknownObjectMessage
                synthesizeSpeech(formString: unknownObjectMessage)
                confidenceLabel.text = ""
                break
            } else {
                let identifier = classification.identifier
                let confidence = Int(classification.confidence * 100)
                let objectMessage = "You found a \(identifier) and I'm \(confidence) percent sure."
                identificationLabel.text = identifier
                confidenceLabel.text = "CONFIDENCE: \(confidence)%"
                synthesizeSpeech(formString: objectMessage)
                break
            }
        }
    }
    
}

extension CameraVC: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.spinnerActivity.stopAnimating()
        self.spinnerActivity.isHidden = true
    }
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            
            do {
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            } catch {
                debugPrint(error)
            }
            
            let image = UIImage(data: photoData!)
            self.capturedImage.image = image
        }
    }
}












