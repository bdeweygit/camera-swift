import AVFoundation

public protocol FrameStreamOutputDelegate: class {
    func frameStream(didOutput frame: CVImageBuffer, with description: CMFormatDescription)
}

class ProxyOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let proxied: FrameStreamOutputDelegate

    init(proxying delegate: FrameStreamOutputDelegate) {
        self.proxied = delegate
    }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // get the frame and description
        if let frame = CMSampleBufferGetImageBuffer(sampleBuffer), let description = CMSampleBufferGetFormatDescription(sampleBuffer) {
            // forward them to the proxied output delegate
            self.proxied.frameStream(didOutput: frame, with: description)
        }
    }
}
