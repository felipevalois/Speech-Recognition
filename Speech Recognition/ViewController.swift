//
//  ViewController.swift
//  Speech Recognition
//
//  Created by Felipe Costa on 8/30/19.
//  Copyright © 2019 Felipe Costa. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var record: UIButton!
    @IBOutlet weak var segment: UISegmentedControl!
    
    
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    var lang: String = "en-US"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        record.isEnabled = false
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            OperationQueue.main.addOperation() {

                switch authStatus {
                    case .authorized:
                        isButtonEnabled = true
                        self.record.isEnabled = isButtonEnabled
                    case .denied:
                        isButtonEnabled = false
                        print("User denied access to speech recognition")
                
                    case .restricted:
                        isButtonEnabled = false
                        print("Speech recognition restricted on this device")
                
                    case .notDetermined:
                        isButtonEnabled = false
                        print("Speech recognition not yet authorized")
                }
            }
        }
    }
    
    
    @IBAction func recordAction(_ sender: Any) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            record.isEnabled = false
            record.setTitle("Record", for: .normal)
        } else {
            try! startRecording()
            record.setTitle("Stop", for: .normal)
        }
    }
    
    func startRecording() throws {
        if let task = recognitionTask {
            task.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [])
//            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.record.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            record.isEnabled = true
        } else {
            record.isEnabled = false
        }
    }
    
    @IBAction func segmentAction(_ sender: Any) {
        switch segment.selectedSegmentIndex {
        case 0:
            lang = "en-US"
            break;
        case 1:
            lang = "es-ES"
            break;
        case 2:
            lang = "pt-BR"
            break;
        default:
            lang = "en-US"
            break;
        }
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
    }
}

