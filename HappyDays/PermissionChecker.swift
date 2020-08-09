//
//  PermissionChecker.swift
//  HappyDays
//
//  Created by Philipp on 09.08.20.
//

import Foundation
import AVFoundation
import Photos
import Speech

class PermissionChecker: ObservableObject {

    private lazy var audioSession: AVAudioSession = {
        AVAudioSession.sharedInstance()
    }()

    @Published var requestAuthorization = false

    @Published var helpText = "In order to work fully, Happy Days needs to read your photo library, record your voice, and transcribe what you said. When you click the button below you will be asked to grant those permissions, but you can change your mind later in Settings."
    @Published var showOpenSettingsButton = false

    func checkPermissions() {
        // check status for all three permissions
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = audioSession.recordPermission == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized

        // make a single boolean out of all three
        requestAuthorization = !(photosAuthorized && recordingAuthorized && transcribeAuthorized)
    }

    func requestPermissions() {
        requestPhotosPermissions()
    }

    private func requestPhotosPermissions() {
        PHPhotoLibrary.requestAuthorization { [unowned self] (status) in
            DispatchQueue.main.async {
                if status == .authorized {
                    self.requestRecordPermissions()
                }
                else {
                    self.helpText = "Photos permission was declined; please enable it in settings then tap Continue again."
                    self.showOpenSettingsButton = true
                }
            }
        }
    }

    private func requestRecordPermissions() {
        audioSession.requestRecordPermission { [unowned self] (allowed) in
            if allowed {
                self.requestTranscribePermissions()
            }
            else {
                self.helpText = "Recording permission was declined; please enable it in settings then tap Continue again."
                self.showOpenSettingsButton = true
            }
        }
    }

    private func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] (status) in
            DispatchQueue.main.async {
                if status == .authorized {
                    self.authorizationComplete()
                }
                else {
                    self.helpText = "Transcription permission was declined; please enable it in settings then tap Continue again."
                    self.showOpenSettingsButton = true
                }
            }
        }
    }

    private func authorizationComplete() {
        requestAuthorization = false
    }
}
