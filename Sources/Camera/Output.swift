import AVFoundation

public protocol FrameStreamOutputDelegate: class {
    func frameStream(didOutput frame: CVImageBuffer, at orientation: AVCaptureVideoOrientation)
}

class ProxyOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var proxied: FrameStreamOutputDelegate?

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // get the frame
        if let frame = CMSampleBufferGetImageBuffer(sampleBuffer) {
            // forward frame and orientation to the proxied output delegate
            self.proxied?.frameStream(didOutput: frame, at: connection.videoOrientation)
        }
    }
}
