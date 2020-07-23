import Foundation

let notifications = NotificationCenter.default
let runtimeError = NSNotification.Name.AVCaptureSessionRuntimeError
let didStartRunning = NSNotification.Name.AVCaptureSessionDidStartRunning
let didStopRunning = NSNotification.Name.AVCaptureSessionDidStopRunning
let wasInterrupted = NSNotification.Name.AVCaptureSessionWasInterrupted
let interruptionEnded = NSNotification.Name.AVCaptureSessionInterruptionEnded

// runtime error
public func imageStreamRuntimeErrorNotification(add observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: runtimeError, object: session)
}
public func imageStreamRuntimeErrorNotification(remove observer: Any) {
    notifications.removeObserver(observer, name: runtimeError, object: session)
}

// did start running
public func imageStreamDidStartRunningNotification(add observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: didStartRunning, object: session)
}
public func imageStreamDidStartRunningNotification(remove observer: Any) {
    notifications.removeObserver(observer, name: didStartRunning, object: session)
}

// did stop running
public func imageStreamDidStopRunningNotification(add observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: didStopRunning, object: session)
}
public func imageStreamDidStopRunningNotification(remove observer: Any) {
    notifications.removeObserver(observer, name: didStopRunning, object: session)
}

// was interrupted
public func imageStreamWasInterrupedNotification(add observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: wasInterrupted, object: session)
}
public func imageStreamWasInterrupedNotification(remove observer: Any) {
    notifications.removeObserver(observer, name: wasInterrupted, object: session)
}

// interruption ended
public func imageStreamInterruptionEndedNotification(add observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: interruptionEnded, object: session)
}
public func imageStreamInterruptionEndedNotification(remove observer: Any) {
    notifications.removeObserver(observer, name: interruptionEnded, object: session)
}
