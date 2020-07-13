import Foundation

let notifications = NotificationCenter.default
let runtimeError = NSNotification.Name.AVCaptureSessionRuntimeError
let didStartRunning = NSNotification.Name.AVCaptureSessionDidStartRunning
let didStopRunning = NSNotification.Name.AVCaptureSessionDidStopRunning
let wasInterrupted = NSNotification.Name.AVCaptureSessionWasInterrupted
let interruptionEnded = NSNotification.Name.AVCaptureSessionInterruptionEnded

// runtime error
public func frameStreamRuntimeErrorNotification(add observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: runtimeError, object: session)
}
public func frameStreamRuntimeErrorNotification(remove observer: Any) {
    notifications.removeObserver(observer, name: runtimeError, object: session)
}

// did start running
public func frameStreamDidStartRunningNotification(add observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: didStartRunning, object: session)
}
public func frameStreamDidStartRunningNotification(remove observer: Any) {
    notifications.removeObserver(observer, name: didStartRunning, object: session)
}

// did stop running
public func frameStreamDidStopRunningNotification(add observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: didStopRunning, object: session)
}
public func frameStreamDidStopRunningNotification(remove observer: Any) {
    notifications.removeObserver(observer, name: didStopRunning, object: session)
}

// was interrupted
public func frameStreamWasInterrupedNotification(add observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: wasInterrupted, object: session)
}
public func frameStreamWasInterrupedNotification(remove observer: Any) {
    notifications.removeObserver(observer, name: wasInterrupted, object: session)
}

// interruption ended
public func frameStreamInterruptionEndedNotification(add observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: interruptionEnded, object: session)
}
public func frameStreamInterruptionEndedNotification(remove observer: Any) {
    notifications.removeObserver(observer, name: interruptionEnded, object: session)
}
