//
//  SoundViewController.swift
//  Wave
//
//  Created by Tian Tong on 11/5/21.
//

import UIKit
import SoundWave

class SoundViewController: UIViewController {
    
    deinit {
        print("Deinit Sound VC")
    }
    
    enum AudioRecodingState {
        case ready
        case recording
        case recorded
        case playing
        case paused

        var audioVisualizationMode: AudioVisualizationView.AudioVisualizationMode {
            switch self {
            case .ready, .recording:
                return .write
            case .paused, .playing, .recorded:
                return .read
            }
        }
    }
    
    // MARK: - Property
    
    let viewModel = SoundViewModel()
    
    var currentState: AudioRecodingState = .ready {
        didSet {
            audioVisualizationView.audioVisualizationMode = currentState.audioVisualizationMode
            undoButton.isHidden = currentState == .ready || currentState == .playing || currentState == .recording
        }
    }
    
    var chronometer: Chronometer?
    
    var isRecording = false
    var isPlaying = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        cleanUp()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.audioMeteringLevelUpdate = { [weak self] meteringLevel in
            guard let self = self, self.audioVisualizationView.audioVisualizationMode == .write else {
                return
            }
            self.audioVisualizationView.add(meteringLevel: meteringLevel)
        }
        
        viewModel.audioDidFinish = { [weak self] in
            self?.playButton.setImage(UIImage(named: "wave_play"), for: .normal)
            self?.currentState = .recorded
            self?.audioVisualizationView.stop()
            self?.isPlaying = false
        }
        
        setupViews()
    }
    
    lazy var recordButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.systemGray
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setImage(UIImage(named: "wave_mic"), for: .normal)
        button.addTarget(self, action: #selector(handleRecord), for: .touchUpInside)
        return button
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.systemBlue
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setImage(UIImage(named: "wave_play"), for: .normal)
        button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        button.alpha = 0
        return button
    }()
    
    lazy var undoButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.systemGray
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        button.setImage(UIImage(named: "wave_undo"), for: .normal)
        button.addTarget(self, action: #selector(handleClear), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    let audioVisualizationView = AudioVisualizationView()
    
    func setupViews() {
        view.backgroundColor = UIColor.secondarySystemBackground
        
        view.addSubview(audioVisualizationView)
        view.addConstts(format: "H:|[v0]|", views: audioVisualizationView)
        view.addConstts(format: "V:[v0(500)]", views: audioVisualizationView)
        audioVisualizationView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        audioVisualizationView.backgroundColor = .secondarySystemBackground
        
        view.addSubview(recordButton)
        view.addConstts(format: "H:[v0(50)]", views: recordButton)
        view.addConstts(format: "V:[v0(50)]", views: recordButton)
        recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        recordButton.topAnchor.constraint(equalTo: audioVisualizationView.bottomAnchor).isActive = true
        
        view.addSubview(playButton)
        view.addConstts(format: "H:[v0(50)]", views: playButton)
        view.addConstts(format: "V:[v0(50)]", views: playButton)
        playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        playButton.topAnchor.constraint(equalTo: audioVisualizationView.bottomAnchor).isActive = true
        
        view.addSubview(undoButton)
        view.addConstts(format: "H:[v0(35)]", views: undoButton)
        view.addConstts(format: "V:[v0(35)]", views: undoButton)
        undoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 100).isActive = true
        undoButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor).isActive = true
    }
    
    // MARK: - Action
    
    @objc func handleRecord() {
        if !isRecording {
            recordButton.tintColor = UIColor.systemRed
            
            do {
                try viewModel.resetRecording()
                currentState = .ready
                audioVisualizationView.reset()
            } catch {
                currentState = .ready
                showAlert(with: error)
            }
            
            viewModel.startRecording { [weak self] soundRecord, error in
                if let error = error {
                    self?.showAlert(with: error)
                    return
                }
                
                self?.currentState = .recording
                
                self?.chronometer = Chronometer()
                self?.chronometer?.start()
            }
        } else {
            recordButton.tintColor = UIColor.systemGray
            recordButton.alpha = 0
            playButton.alpha = 1
            
            chronometer?.stop()
            chronometer = nil

            viewModel.currentAudioRecord!.meteringLevels = audioVisualizationView.scaleSoundDataToFitScreen()
            audioVisualizationView.audioVisualizationMode = .read

            do {
                try viewModel.stopRecording()
                currentState = .recorded
            } catch {
                currentState = .ready
                showAlert(with: error)
            }
        }
        
        isRecording.toggle()
    }
    
    @objc func handlePlay() {
        if !isPlaying {
            playButton.setImage(UIImage(named: "wave_pause"), for: .normal)
            
            do {
                let duration = try viewModel.startPlaying()
                currentState = .playing
                audioVisualizationView.meteringLevels = viewModel.currentAudioRecord!.meteringLevels
                audioVisualizationView.play(for: duration)
            } catch {
                showAlert(with: error)
            }
        } else {
            playButton.setImage(UIImage(named: "wave_play"), for: .normal)
            
            do {
                try viewModel.pausePlaying()
                currentState = .paused
                audioVisualizationView.pause()
            } catch {
                showAlert(with: error)
            }
        }
        
        isPlaying.toggle()
    }
    
    @objc func handleClear() {
        do {
            try viewModel.resetRecording()
            audioVisualizationView.reset()
            currentState = .ready
            
            recordButton.alpha = 1
            playButton.alpha = 0
        } catch {
            showAlert(with: error)
        }
    }
    
    // MARK: - Method
    
    func cleanUp() {
        do {
            switch currentState {
            case .recording:
                try AudioRecorderManager.shared.stopRecording()
            case .playing:
                try AudioPlayerManager.shared.stop()
            case .ready, .paused, .recorded:
                return
            }
        } catch {
            showAlert(with: error)
        }
    }
    
}
