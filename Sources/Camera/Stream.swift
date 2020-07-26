import AVFoundation

public enum StartImageStreamResult {
    case success
    case couldNotAddInput
    case couldNotAddOutput
    case wasAlreadyStarted
    case couldNotSetPreset
    case couldNotCreateInput
    case sessionFailedToStart
    case couldNotDiscoverAnyDevices
}

public enum StopImageStreamResult {
    case success
    case wasAlreadyStopped
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
        // check if already running
        if session.isRunning {
            return completion(.wasAlreadyStarted)
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
        if !session.canSetSessionPreset(settings.preset) {
            session.commitConfiguration()
            return completion(.couldNotSetPreset)
        }
        session.sessionPreset = settings.preset

        // add input
        if !session.canAddInput(input) {
            session.commitConfiguration()
            return completion(.couldNotAddInput)
        }
        session.addInput(input)

        // add ouput
        if !session.canAddOutput(output) {
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

        if session.isRunning {
            completion(.success)
        } else {
            completion(.sessionFailedToStart)
        }
    }
}

public func stopImageStream(completionHandler completion: @escaping (StopImageStreamResult) -> Void) {
    sessionQueue.async {
        if session.isRunning {
            // stop and clean the session
            session.stopRunning()
            cleanSession()

            completion(.success)
        } else {
            completion(.wasAlreadyStopped)
        }
    }
}
