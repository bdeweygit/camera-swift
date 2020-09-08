import AVFoundation

public typealias CameraSettings = (
    preset: AVCaptureSession.Preset,
    position: AVCaptureDevice.Position,
    deviceTypes: [AVCaptureDevice.DeviceType]
)

public enum CameraImageStreamStartResult {
    case success
    case couldNotAddInput
    case couldNotAddOutput
    case couldNotSetPreset
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
    func cameraImageStreamDidOutput(_ image: CVImageBuffer, at orientation: AVCaptureVideoOrientation)
}

public struct Camera {
    private static let session = AVCaptureSession()
    private static let proxyOutputDelegate = ProxyOutputDelegate()
    private static let sessionQueue = DispatchQueue(label: "Camera.SessionQueue", attributes: [], autoreleaseFrequency: .workItem)

    // MARK: Session Configuration

    private static func configureSession(_ outputDelegate: CameraImageStreamOutputDelegate, _ qos: DispatchQoS, _ settings: CameraSettings, _ input: AVCaptureDeviceInput, _ output: AVCaptureVideoDataOutput) -> CameraImageStreamStartResult {
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

        // add ouput
        guard self.session.canAddOutput(output) else { return .couldNotAddOutput }
        self.session.addOutput(output)

        // proxy the output delegate and create the output queue
        self.proxyOutputDelegate.proxied = outputDelegate
        let outputQueue = DispatchQueue(label: "Camera.ImageStreamOutputQueue", qos: qos, attributes: [], autoreleaseFrequency: .workItem)

        // set delegate and queue
        output.setSampleBufferDelegate(self.proxyOutputDelegate, queue: outputQueue)

        return .success
    }

    // MARK: Image Stream Operation

    public static func startImageStream(to outputDelegate: CameraImageStreamOutputDelegate, withQualityOf qos: DispatchQoS, using settings: CameraSettings, _ completion: @escaping (CameraImageStreamStartResult) -> Void) {
        self.sessionQueue.async {
            // verify session is not running
            guard !self.session.isRunning else { return completion(.sessionIsAlreadyRunning) }

            // discover the best available device
            let discovered = AVCaptureDevice.DiscoverySession(deviceTypes: settings.deviceTypes, mediaType: .video, position: settings.position)
            guard let device = discovered.devices.first else { return completion(.couldNotDiscoverAnyDevices) }

            // create the output and input
            let output = AVCaptureVideoDataOutput()
            guard let input = try? AVCaptureDeviceInput(device: device) else { return completion(.couldNotCreateInput) }

            // configure the session
            let result = self.configureSession(outputDelegate, qos, settings, input, output)
            guard result == .success else { return completion(result) }

            // start the session
            self.session.startRunning()

            // verify session is running
            guard self.session.isRunning else { return completion(.sessionFailedToStart) }

            completion(.success)
        }
    }

    public static func stopImageStream(_ completion: @escaping (CameraImageStreamStopResult) -> Void) {
        self.sessionQueue.async {
            // verify session is running
            guard self.session.isRunning else { return completion(.sessionIsAlreadyNotRunning) }

            // stop the session
            self.session.stopRunning()

            completion(.success)
        }
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
