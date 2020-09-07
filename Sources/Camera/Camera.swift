import AVFoundation

public typealias CameraSettings = (
    preset: AVCaptureSession.Preset,
    position: AVCaptureDevice.Position,
    deviceTypes: [AVCaptureDevice.DeviceType]
)

public enum StartImageStreamResult {
    case success
    case couldNotAddInput
    case couldNotAddOutput
    case couldNotSetPreset
    case couldNotCreateInput
    case sessionFailedToStart
    case sessionIsAlreadyRunning
    case couldNotDiscoverAnyDevices
}

public enum StopImageStreamResult {
    case success
    case sessionIsAlreadyNotRunning
}

public protocol CameraImageStreamOutputDelegate: class {
    func cameraImageStreamDidOutput(_ image: CVImageBuffer, at orientation: AVCaptureVideoOrientation)
}

fileprivate let session = AVCaptureSession()
fileprivate let proxyOutputDelegate = ProxyOutputDelegate()
fileprivate let sessionQueue = DispatchQueue(label: "Camera.SessionQueue", attributes: [], autoreleaseFrequency: .workItem)

public struct Camera {
    // MARK: Session Configuration

    private static func configureSession(_ outputDelegate: CameraImageStreamOutputDelegate, _ qos: DispatchQoS, _ settings: CameraSettings, _ input: AVCaptureDeviceInput, _ output: AVCaptureVideoDataOutput) -> StartImageStreamResult {
        // begin and later commit configuration
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // remove any prior inputs and outputs
        session.inputs.forEach({ session.removeInput($0) })
        session.outputs.forEach({ session.removeOutput($0) })

        // set preset
        guard session.canSetSessionPreset(settings.preset) else { return .couldNotSetPreset }
        session.sessionPreset = settings.preset

        // add input
        guard session.canAddInput(input) else { return .couldNotAddInput }
        session.addInput(input)

        // add ouput
        guard session.canAddOutput(output) else { return .couldNotAddOutput }
        session.addOutput(output)

        // proxy the output delegate and create the output queue
        proxyOutputDelegate.proxied = outputDelegate
        let outputQueue = DispatchQueue(label: "Camera.ImageStreamOutputQueue", qos: qos, attributes: [], autoreleaseFrequency: .workItem)

        // set delegate and queue
        output.setSampleBufferDelegate(proxyOutputDelegate, queue: outputQueue)

        return .success
    }

    // MARK: Image Stream Operation

    public static func startImageStream(to outputDelegate: CameraImageStreamOutputDelegate, withQualityOf qos: DispatchQoS, using settings: CameraSettings, _ completion: @escaping (StartImageStreamResult) -> Void) {
        sessionQueue.async {
            // verify session is not running
            guard !session.isRunning else { return completion(.sessionIsAlreadyRunning) }

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
            session.startRunning()

            // verify session is running
            guard session.isRunning else { return completion(.sessionFailedToStart) }

            completion(.success)
        }
    }

    public static func stopImageStream(_ completion: @escaping (StopImageStreamResult) -> Void) {
        sessionQueue.async {
            // verify session is running
            guard session.isRunning else { return completion(.sessionIsAlreadyNotRunning) }

            // stop the session
            session.stopRunning()

            completion(.success)
        }
    }

    // MARK: Notification Observation

    // runtime error
    public static func runtimeErrorNotificationAdd(_ observer: Any, calling selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: .AVCaptureSessionRuntimeError, object: session)
    }
    public static func runtimeErrorNotificationRemove(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: .AVCaptureSessionRuntimeError, object: session)
    }

    // did start running
    public static func didStartRunningNotificationAdd(_ observer: Any, calling selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: .AVCaptureSessionDidStartRunning, object: session)
    }
    public static func didStartRunningNotificationRemove(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: .AVCaptureSessionDidStartRunning, object: session)
    }

    // did stop running
    public static func didStopRunningNotificationAdd(_ observer: Any, calling selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: .AVCaptureSessionDidStopRunning, object: session)
    }
    public static func didStopRunningNotificationRemove(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: .AVCaptureSessionDidStopRunning, object: session)
    }

    // was interrupted
    public static func wasInterrupedNotificationAdd(_ observer: Any, calling selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: .AVCaptureSessionWasInterrupted, object: session)
    }
    public static func wasInterrupedNotificationRemove(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: .AVCaptureSessionWasInterrupted, object: session)
    }

    // interruption ended
    public static func interruptionEndedNotificationAdd(_ observer: Any, calling selector: Selector) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: .AVCaptureSessionInterruptionEnded, object: session)
    }
    public static func interruptionEndedNotificationRemove(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: .AVCaptureSessionInterruptionEnded, object: session)
    }
}
