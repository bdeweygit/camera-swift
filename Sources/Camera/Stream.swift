import AVFoundation

public enum FrameStreamError: Error {
    case alreadyRunning
    case couldNotAddInput
    case couldNotAddOutput
    case couldNotSetPreset
    case couldNotCreateInput
    case couldNotDiscoverAnyDevices
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

public func startFrameStream(to outputDelegate: FrameStreamOutputDelegate, using settings: FrameStreamSettings) throws {
    // throw if already running
    if session.isRunning {
        throw FrameStreamError.alreadyRunning
    }

    // discover the best available device
    let discovered = AVCaptureDevice.DiscoverySession(deviceTypes: settings.deviceTypes, mediaType: .video, position: settings.position)
    guard let device = discovered.devices.first else {
        throw FrameStreamError.couldNotDiscoverAnyDevices
    }

    // create the output and input
    let output = AVCaptureVideoDataOutput()
    guard let input = try? AVCaptureDeviceInput(device: device) else {
        throw FrameStreamError.couldNotCreateInput
    }

    // clean the session before configuring it
    cleanSession()

    // begin session configuration
    session.beginConfiguration()

    // set preset
    if !session.canSetSessionPreset(settings.preset) {
        session.commitConfiguration()
        throw FrameStreamError.couldNotSetPreset
    }
    session.sessionPreset = settings.preset

    // add input
    if !session.canAddInput(input) {
        session.commitConfiguration()
        throw FrameStreamError.couldNotAddInput
    }
    session.addInput(input)

    // add ouput
    if !session.canAddOutput(output) {
        session.commitConfiguration()
        throw FrameStreamError.couldNotAddOutput
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
    sessionQueue.async {
        session.startRunning()
    }
}

public func stopFrameStream() {
    if session.isRunning {
        sessionQueue.async {
            // stop and clean the session
            session.stopRunning()
            cleanSession()
        }
    }
}
