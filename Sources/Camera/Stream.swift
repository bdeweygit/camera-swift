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

let session = AVCaptureSession()
let proxyOutputDelegate = ProxyOutputDelegate()
let sessionQueue = DispatchQueue(label: "Camera.ImageStreamSessionQueue", attributes: [], autoreleaseFrequency: .workItem)

func configureSession(_ outputDelegate: ImageStreamOutputDelegate, _ qos: DispatchQoS, _ settings: CameraSettings, _ input: AVCaptureDeviceInput, _ output: AVCaptureVideoDataOutput) -> StartImageStreamResult {
    // remove any prior inputs and outputs
    session.inputs.forEach { input in session.removeInput(input)}
    session.outputs.forEach { output in session.removeOutput(output)}

    // begin and later commit configuration
    session.beginConfiguration()
    defer { session.commitConfiguration() }

    // set preset
    guard session.canSetSessionPreset(settings.preset) else {
        return .couldNotSetPreset
    }
    session.sessionPreset = settings.preset

    // add input
    guard session.canAddInput(input) else {
        return .couldNotAddInput
    }
    session.addInput(input)

    // add ouput
    guard session.canAddOutput(output) else {
        return .couldNotAddOutput
    }
    session.addOutput(output)

    // proxy the output delegate and create the output queue
    proxyOutputDelegate.proxied = outputDelegate
    let outputQueue = DispatchQueue(label: "Camera.ImageStreamOutputQueue", qos: qos, attributes: [], autoreleaseFrequency: .workItem)

    // set delegate and queue
    output.setSampleBufferDelegate(proxyOutputDelegate, queue: outputQueue)

    return .success
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

        // configure the session
        let result = configureSession(outputDelegate, qos, settings, input, output)
        guard result == .success else {
            return completion(result)
        }

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

        // stop the session
        session.stopRunning()

        completion(.success)
    }
}
