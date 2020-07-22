import AVFoundation

public protocol FrameStreamOutputDelegate: class {
    func frameStream(didOutput frame: CVImageBuffer, at orientation: AVCaptureVideoOrientation)
}

class ProxyOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let proxied: FrameStreamOutputDelegate

    init(proxying delegate: FrameStreamOutputDelegate) {
        self.proxied = delegate
    }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // get the frame
        if let frame = CMSampleBufferGetImageBuffer(sampleBuffer) {
            // forward frame and orientation to the proxied output delegate
            self.proxied.frameStream(didOutput: frame, at: connection.videoOrientation)
        }
    }
}
