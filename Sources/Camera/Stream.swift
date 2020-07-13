import AVFoundation

public enum FrameStreamError: Error {
    case alreadyRunning
    case couldNotAddInput
    case couldNotAddOutput
    case couldNotSetPreset
    case couldNotCreateInput
    case couldNotCreateDevice
}

public struct FrameStreamSettings {
    let deviceType: AVCaptureDevice.DeviceType
    let position: AVCaptureDevice.Position
    let preset: AVCaptureSession.Preset
    let videoSettings: [String: Int]
    let qualityOfService: DispatchQoS
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

    // create the device
    guard let device = AVCaptureDevice.default(settings.deviceType, for: .video, position: settings.position) else {
        throw FrameStreamError.couldNotCreateDevice
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

    // set delegate, queue, and video settings
    output.setSampleBufferDelegate(proxyOutputDelegate, queue: outputQueue)
    output.videoSettings = settings.videoSettings

    // commit session configuration atomically
    session.commitConfiguration()

    // start the session
    sessionQueue.async {
        session.startRunning()
    }
}

public func stopFrameStream() {
    sessionQueue.async {
        // stop and clean the session
        session.stopRunning()
        cleanSession()
    }
}
