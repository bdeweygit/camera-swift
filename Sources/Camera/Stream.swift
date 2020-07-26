import AVFoundation

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

public struct CameraSettings {
    public let deviceTypes: [AVCaptureDevice.DeviceType]
    public let position: AVCaptureDevice.Position
    public let preset: AVCaptureSession.Preset

    public init(deviceTypes: [AVCaptureDevice.DeviceType], position: AVCaptureDevice.Position, preset: AVCaptureSession.Preset) {
        self.deviceTypes = deviceTypes
        self.position = position
        self.preset = preset
    }
}

let session = AVCaptureSession()
let proxyOutputDelegate = ProxyOutputDelegate()
let sessionQueue = DispatchQueue(label: "Camera.ImageStreamSessionQueue", attributes: [], autoreleaseFrequency: .workItem)

func cleanSession() {
    // begin session configuration
    session.beginConfiguration()

    // remove inputs and outputs
    session.inputs.forEach { input in session.removeInput(input)}
    session.outputs.forEach { output in session.removeOutput(output)}

    // commit session configuration atomically
    session.commitConfiguration()
}

public func startImageStream(to outputDelegate: ImageStreamOutputDelegate, withQualityOf qos: DispatchQoS, using settings: CameraSettings, completionHandler completion: @escaping (StartImageStreamResult) -> Void) {
    sessionQueue.async {
        // verify session is not running
        guard !session.isRunning else {
            return completion(.sessionIsAlreadyRunning)
        }

        // discover the best available device
        let discovered = AVCaptureDevice.DiscoverySession(deviceTypes: settings.deviceTypes, mediaType: .video, position: settings.position)
        guard let device = discovered.devices.first else {
            return completion(.couldNotDiscoverAnyDevices)
        }

        // create the output and input
        let output = AVCaptureVideoDataOutput()
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            return completion(.couldNotCreateInput)
        }

        // clean the session before configuring it
        cleanSession()

        // begin session configuration
        session.beginConfiguration()

        // set preset
        guard session.canSetSessionPreset(settings.preset) else {
            session.commitConfiguration()
            return completion(.couldNotSetPreset)
        }
        session.sessionPreset = settings.preset

        // add input
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            return completion(.couldNotAddInput)
        }
        session.addInput(input)

        // add ouput
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return completion(.couldNotAddOutput)
        }
        session.addOutput(output)

        // proxy the output delegate and create the output queue
        proxyOutputDelegate.proxied = outputDelegate
        let outputQueue = DispatchQueue(label: "Camera.ImageStreamOutputQueue", qos: qos, attributes: [], autoreleaseFrequency: .workItem)

        // set delegate and queue
        output.setSampleBufferDelegate(proxyOutputDelegate, queue: outputQueue)

        // commit session configuration atomically
        session.commitConfiguration()

        // start the session
        session.startRunning()

        // verify session is running
        guard session.isRunning else {
            return completion(.sessionFailedToStart)
        }
        completion(.success)
    }
}

public func stopImageStream(completionHandler completion: @escaping (StopImageStreamResult) -> Void) {
    sessionQueue.async {
        // verify session is running
        guard session.isRunning else {
            return completion(.sessionIsAlreadyNotRunning)
        }

        // stop and clean the session
        session.stopRunning()
        cleanSession()

        completion(.success)
    }
}
