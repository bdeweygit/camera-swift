import AVFoundation

public enum StartFrameStreamResult {
    case success
    case couldNotAddInput
    case couldNotAddOutput
    case wasAlreadyStarted
    case couldNotSetPreset
    case couldNotCreateInput
    case couldNotDiscoverAnyDevices
}

public enum StopFrameStreamResult {
    case success
    case wasAlreadyStopped
}

public struct FrameStreamSettings {
    public let deviceTypes: [AVCaptureDevice.DeviceType]
    public let position: AVCaptureDevice.Position
    public let preset: AVCaptureSession.Preset
    public let qualityOfService: DispatchQoS

    public init(deviceTypes: [AVCaptureDevice.DeviceType], position: AVCaptureDevice.Position, preset: AVCaptureSession.Preset, qualityOfService: DispatchQoS) {
        self.deviceTypes = deviceTypes
        self.position = position
        self.preset = preset
        self.qualityOfService = qualityOfService
    }
}

let session = AVCaptureSession()
let sessionQueue = DispatchQueue(label: "Camera.FrameStreamSessionQueue", attributes: [], autoreleaseFrequency: .workItem)

func cleanSession() {
    // begin session configuration
    session.beginConfiguration()

    // remove inputs and outputs
    session.inputs.forEach { input in session.removeInput(input)}
    session.outputs.forEach { output in session.removeOutput(output)}

    // commit session configuration atomically
    session.commitConfiguration()
}

public func startFrameStream(to outputDelegate: FrameStreamOutputDelegate, using settings: FrameStreamSettings, completion: @escaping (StartFrameStreamResult) -> Void) {
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

        // create the proxy output delegate and output queue
        let proxyOutputDelegate = ProxyOutputDelegate(proxying: outputDelegate)
        let outputQueue = DispatchQueue(label: "Camera.FrameStreamOutputQueue", qos: settings.qualityOfService, attributes: [], autoreleaseFrequency: .workItem)

        // set delegate and queue
        output.setSampleBufferDelegate(proxyOutputDelegate, queue: outputQueue)

        // commit session configuration atomically
        session.commitConfiguration()

        // start the session
        session.startRunning()

        completion(.success)
    }
}

public func stopFrameStream(completion: @escaping (StopFrameStreamResult) -> Void) {
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
