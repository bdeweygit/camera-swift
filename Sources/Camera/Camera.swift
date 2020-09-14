import AVFoundation

public typealias CameraSettings = (
    preset: AVCaptureSession.Preset,
    position: AVCaptureDevice.Position,
    deviceTypes: [AVCaptureDevice.DeviceType],
    includeDepthMap: Bool
)

public enum CameraImageStreamStartResult {
    case success
    case couldNotAddInput
    case couldNotAddOutput
    case couldNotSetPreset
    case couldNotLockDevice
    case couldNotCreateInput
    case sessionFailedToStart
    case sessionIsAlreadyRunning
    case couldNotDiscoverAnyDevices
}

public enum CameraImageStreamStopResult {
    case success
    case sessionIsAlreadyNotRunning
}

public protocol CameraImageStreamOutputDelegate: class {
    func cameraImageStreamDidOutput(_ image: CVImageBuffer?, _ depthMap: CVImageBuffer?, at orientation: AVCaptureVideoOrientation?)
}

public struct Camera {
    private static let session = AVCaptureSession()
    private static let proxyOutputDelegate = ProxyOutputDelegate()
    private static var outputSync: AVCaptureDataOutputSynchronizer?
    private static let sessionQueue = DispatchQueue(label: "Camera.SessionQueue", attributes: [], autoreleaseFrequency: .workItem)

    // MARK: Session Configuration

    private static func configureSession(_ outputDelegate: CameraImageStreamOutputDelegate, _ qos: DispatchQoS, _ settings: CameraSettings, _ input: AVCaptureDeviceInput, _ videoOutput: AVCaptureVideoDataOutput, _ depthOutput: AVCaptureDepthDataOutput?) -> CameraImageStreamStartResult {
        // begin and later commit configuration
        self.session.beginConfiguration()
        defer { self.session.commitConfiguration() }

        // remove any prior inputs and outputs
        self.session.inputs.forEach({ self.session.removeInput($0) })
        self.session.outputs.forEach({ self.session.removeOutput($0) })

        // set preset
        guard self.session.canSetSessionPreset(settings.preset) else { return .couldNotSetPreset }
        self.session.sessionPreset = settings.preset

        // add input
        guard self.session.canAddInput(input) else { return .couldNotAddInput }
        self.session.addInput(input)

        // add video ouput
        guard self.session.canAddOutput(videoOutput) else { return .couldNotAddOutput }
        self.session.addOutput(videoOutput)
        var dataOutputs: [AVCaptureOutput] = [videoOutput]

        // add depth output
        if let depthOutput = depthOutput, input.device.activeFormat.supportedDepthDataFormats.count > 0 {
            guard self.session.canAddOutput(depthOutput) else { return .couldNotAddOutput }
            self.session.addOutput(depthOutput)
            dataOutputs.append(depthOutput)

            // smooth depth data
            depthOutput.isFilteringEnabled = true

            // maximize the device's depth format resolution
            let depthFormat = input.device.activeFormat.supportedDepthDataFormats.filter({ $0.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_DepthFloat32 }).max(by: { $0.formatDescription.dimensions.width < $1.formatDescription.dimensions.width })

            guard let _ = try? input.device.lockForConfiguration() else { return .couldNotLockDevice }
            input.device.activeDepthDataFormat = depthFormat
            input.device.unlockForConfiguration()
        }

        // proxy the output delegate and create the output queue
        self.proxyOutputDelegate.proxy(outputDelegate, withOutputs: videoOutput, depthOutput)
        let outputQueue = DispatchQueue(label: "Camera.ImageStreamOutputQueue", qos: qos, attributes: [], autoreleaseFrequency: .workItem)

        // create and setup the output synchronizer
        self.outputSync = AVCaptureDataOutputSynchronizer(dataOutputs: dataOutputs)
        self.outputSync!.setDelegate(self.proxyOutputDelegate, queue: outputQueue)

        return .success
    }

    // MARK: Image Stream Operation

    public static func startImageStream(to outputDelegate: CameraImageStreamOutputDelegate, using settings: CameraSettings, withQualityOf qos: DispatchQoS, _ completion: @escaping (CameraImageStreamStartResult) -> Void) {
        self.sessionQueue.async(execute: {
            // verify session is not running
            guard !self.session.isRunning else { return completion(.sessionIsAlreadyRunning) }

            // discover the best available device
            let discovered = AVCaptureDevice.DiscoverySession(deviceTypes: settings.deviceTypes, mediaType: .video, position: settings.position)
            guard let device = discovered.devices.first else { return completion(.couldNotDiscoverAnyDevices) }

            // create the input
            guard let input = try? AVCaptureDeviceInput(device: device) else { return completion(.couldNotCreateInput) }

            // create the video and depth outputs
            let videoOutput = AVCaptureVideoDataOutput()
            let depthOutput = settings.includeDepthMap ? AVCaptureDepthDataOutput() : nil

            // configure the session
            let result = self.configureSession(outputDelegate, qos, settings, input, videoOutput, depthOutput)
            guard result == .success else { return completion(result) }

            // start the session
            self.session.startRunning()

            // verify session is running
            guard self.session.isRunning else { return completion(.sessionFailedToStart) }

            completion(.success)
        })
    }

    public static func stopImageStream(_ completion: @escaping (CameraImageStreamStopResult) -> Void) {
        self.sessionQueue.async(execute: {
            // verify session is running
            guard self.session.isRunning else { return completion(.sessionIsAlreadyNotRunning) }

            // stop the session
            self.session.stopRunning()

            completion(.success)
        })
    }

    // MARK: Notification Observation

    // runtime error
    public static func runtimeErrorNotificationAdd(_ observer: Any, calling selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: .AVCaptureSessionRuntimeError, object: self.session)
    }
    public static func runtimeErrorNotificationRemove(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: .AVCaptureSessionRuntimeError, object: self.session)
    }

    // did start running
    public static func didStartRunningNotificationAdd(_ observer: Any, calling selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: .AVCaptureSessionDidStartRunning, object: self.session)
    }
    public static func didStartRunningNotificationRemove(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: .AVCaptureSessionDidStartRunning, object: self.session)
    }

    // did stop running
    public static func didStopRunningNotificationAdd(_ observer: Any, calling selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: .AVCaptureSessionDidStopRunning, object: self.session)
    }
    public static func didStopRunningNotificationRemove(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: .AVCaptureSessionDidStopRunning, object: self.session)
    }

    // was interrupted
    public static func wasInterrupedNotificationAdd(_ observer: Any, calling selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: .AVCaptureSessionWasInterrupted, object: self.session)
    }
    public static func wasInterrupedNotificationRemove(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: .AVCaptureSessionWasInterrupted, object: self.session)
    }

    // interruption ended
    public static func interruptionEndedNotificationAdd(_ observer: Any, calling selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: .AVCaptureSessionInterruptionEnded, object: self.session)
    }
    public static func interruptionEndedNotificationRemove(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: .AVCaptureSessionInterruptionEnded, object: self.session)
    }
}
