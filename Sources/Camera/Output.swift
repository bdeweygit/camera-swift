import AVFoundation

public protocol ImageStreamOutputDelegate: class {
    func imageStream(didOutput image: CVImageBuffer, at orientation: AVCaptureVideoOrientation)
}

class ProxyOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var proxied: ImageStreamOutputDelegate?

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // get the image
        if let image = CMSampleBufferGetImageBuffer(sampleBuffer) {
            // forward image and orientation to the proxied output delegate
            self.proxied?.imageStream(didOutput: image, at: connection.videoOrientation)
        }
    }
}
