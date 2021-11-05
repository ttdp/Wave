//
//  SoundViewModel.swift
//  Wave
//
//  Created by Tian Tong on 11/5/21.
//

import Foundation

class SoundViewModel {
    
    deinit {
        print("Deinit Sound VM")
    }
    
    // MARK: - Property
    
    var audioVisualizationTimeInterval: TimeInterval = 0.05
    
    var currentAudioRecord: SoundRecord?
    var isPlaying = false
    
    var audioMeteringLevelUpdate: ((Float) -> ())?
    var audioDidFinish: (() -> ())?
    
    init() {
        // notifications update metering levels
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMeteringLevelUpdate),
                                               name: .audioPlayerManagerMeteringLevelDidUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMeteringLevelUpdate),
                                               name: .audioRecorderManagerMeteringLevelDidUpdateNotification, object: nil)
        
        // notifications audio finished
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishRecordOrPlayAudio),
                                               name: .audioPlayerManagerMeteringLevelDidFinishNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishRecordOrPlayAudio),
                                               name: .audioRecorderManagerMeteringLevelDidFinishNotification, object: nil)
    }
    
    // MARK: - Recording
    
    func askAudioRecordingPermission(completion: ((Bool) -> Void)? = nil) {
        return AudioRecorderManager.shared.askPermission(completion: completion)
    }
    
    func startRecording(completion: @escaping (SoundRecord?, Error?) -> Void) {
        AudioRecorderManager.shared.startRecording(with: self.audioVisualizationTimeInterval, completion: { [weak self] url, error in
            guard let url = url else {
                completion(nil, error!)
                return
            }

            self?.currentAudioRecord = SoundRecord(audioFilePathLocal: url, meteringLevels: [])
            print("sound record created at url \(url.absoluteString))")
            completion(self?.currentAudioRecord, nil)
        })
    }
    
    func stopRecording() throws {
        try AudioRecorderManager.shared.stopRecording()
    }
    
    func resetRecording() throws {
        try AudioRecorderManager.shared.reset()
        isPlaying = false
        currentAudioRecord = nil
    }
    
    // MARK: - Playing
    
    func startPlaying() throws -> TimeInterval {
        guard let currentAudioRecord = currentAudioRecord else {
            throw AudioErrorType.audioFileWrongPath
        }

        if isPlaying {
            return try AudioPlayerManager.shared.resume()
        } else {
            guard let audioFilePath = currentAudioRecord.audioFilePathLocal else {
                fatalError("tried to unwrap audio file path that is nil")
            }

            isPlaying = true
            return try AudioPlayerManager.shared.play(at: audioFilePath, with: audioVisualizationTimeInterval)
        }
    }
    
    func pausePlaying() throws {
        try AudioPlayerManager.shared.pause()
    }
    
    // MARK: - Notification
    
    @objc func didReceiveMeteringLevelUpdate(_ notification: Notification) {
        let percentage = notification.userInfo![audioPercentageUserInfoKey] as! Float
        audioMeteringLevelUpdate?(percentage)
    }
    
    @objc private func didFinishRecordOrPlayAudio(_ notification: Notification) {
        audioDidFinish?()
    }
    
}
