import AVFoundation

class ProxyOutputDelegate: NSObject, AVCaptureDataOutputSynchronizerDelegate {
    private weak var proxied: CameraImageStreamOutputDelegate?
    private weak var videoOutput: AVCaptureVideoDataOutput?
    private weak var depthOutput: AVCaptureDepthDataOutput?

    func proxy(_ proxied: CameraImageStreamOutputDelegate, withOutputs videoOutput: AVCaptureVideoDataOutput, _ depthOutput: AVCaptureDepthDataOutput?) {
        self.proxied = proxied
        self.videoOutput = videoOutput
        self.depthOutput = depthOutput
    }

    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {

        var image: CVImageBuffer?
        var depthMap: CVImageBuffer?
        var orientation: AVCaptureVideoOrientation?

        // get the image
        if let videoOutput = self.videoOutput, let syncedSampleBufferData = synchronizedDataCollection.synchronizedData(for: videoOutput) as? AVCaptureSynchronizedSampleBufferData {
            image = syncedSampleBufferData.sampleBuffer.imageBuffer

            // get the orientation
            if let videoConnection = videoOutput.connection(with: .video) {
                orientation = videoConnection.videoOrientation
            }
        }

        // get the depth map
        if let depthOutput = self.depthOutput, let syncedDepthData = synchronizedDataCollection.synchronizedData(for: depthOutput) as? AVCaptureSynchronizedDepthData, !syncedDepthData.depthDataWasDropped {
            depthMap = syncedDepthData.depthData.depthDataMap
        }

        // forward image, depth map, and orientation to the proxied output delegate
        self.proxied?.cameraImageStreamDidOutput(image, depthMap, at: orientation)
    }
}
