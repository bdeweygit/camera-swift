import AVFoundation

class ProxyOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
   weak var proxied: CameraImageStreamOutputDelegate?

   func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
       // get the image
       guard let image = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

       // forward image and orientation to the proxied output delegate
       self.proxied?.cameraImageStreamDidOutput(image, at: connection.videoOrientation)
   }
}
