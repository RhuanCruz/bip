import AudioToolbox
import AVFoundation
import Combine
import SwiftUI

@MainActor
final class VoiceInputMonitor: NSObject, ObservableObject, @unchecked Sendable {
    @Published private(set) var levels: [CGFloat]
    @Published private(set) var isRecording = false
    @Published private(set) var permissionDenied = false

    private let sampleCount = 34
    private var activeRecordingURL: URL?
    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    override init() {
        self.levels = Array(repeating: 0.12, count: sampleCount)
        super.init()
    }

    deinit {
        timer?.invalidate()
        recorder?.stop()
    }

    func start() {
        permissionDenied = false

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            startRecording()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    granted ? self.startRecording() : self.markPermissionDenied()
                }
            }
        case .denied, .restricted:
            markPermissionDenied()
        @unknown default:
            markPermissionDenied()
        }
    }

    func stop() {
        stopRecording(deleteFile: true)
    }

    func finishRecording() -> URL? {
        stopRecording(deleteFile: false)
    }

    private func stopRecording(deleteFile: Bool) -> URL? {
        let url = activeRecordingURL
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        activeRecordingURL = nil
        isRecording = false
        levels = Array(repeating: 0.12, count: sampleCount)

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if deleteFile, let url {
            try? FileManager.default.removeItem(at: url)
        }

        return url
    }

    private func startRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true)

            let url = recordingURL
            try? FileManager.default.removeItem(at: url)

            let recorder = try AVAudioRecorder(url: url, settings: recordingSettings)
            recorder.isMeteringEnabled = true
            recorder.record()

            self.recorder = recorder
            activeRecordingURL = url
            isRecording = true
            startMetering()
        } catch {
            stop()
            permissionDenied = true
        }
    }

    private func startMetering() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: 0.045,
            target: self,
            selector: #selector(captureMeterLevel),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func captureMeterLevel() {
        guard let recorder else { return }

        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalized = normalizedPower(power)

        levels.removeFirst()
        levels.append(normalized)
    }

    private func normalizedPower(_ decibels: Float) -> CGFloat {
        let minimumDecibels: Float = -52
        guard decibels > minimumDecibels else { return 0.08 }

        let clamped = min(0, decibels)
        let linear = (clamped - minimumDecibels) / abs(minimumDecibels)
        return CGFloat(pow(Double(linear), 0.55))
    }

    private func markPermissionDenied() {
        stop()
        permissionDenied = true
    }

    private var recordingURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("bip-voice-input-\(UUID().uuidString)")
            .appendingPathExtension("aac")
    }

    private var recordingSettings: [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
    }
}
