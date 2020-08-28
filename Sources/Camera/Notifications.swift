import Foundation

let notifications = NotificationCenter.default
let runtimeError = NSNotification.Name.AVCaptureSessionRuntimeError
let didStartRunning = NSNotification.Name.AVCaptureSessionDidStartRunning
let didStopRunning = NSNotification.Name.AVCaptureSessionDidStopRunning
let wasInterrupted = NSNotification.Name.AVCaptureSessionWasInterrupted
let interruptionEnded = NSNotification.Name.AVCaptureSessionInterruptionEnded

// runtime error
public func imageStreamRuntimeErrorNotificationAdd(_ observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: runtimeError, object: session)
}
public func imageStreamRuntimeErrorNotificationRemove(_ observer: Any) {
    notifications.removeObserver(observer, name: runtimeError, object: session)
}

// did start running
public func imageStreamDidStartRunningNotificationAdd(_ observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: didStartRunning, object: session)
}
public func imageStreamDidStartRunningNotificationRemove(_ observer: Any) {
    notifications.removeObserver(observer, name: didStartRunning, object: session)
}

// did stop running
public func imageStreamDidStopRunningNotificationAdd(_ observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: didStopRunning, object: session)
}
public func imageStreamDidStopRunningNotificationRemove(_ observer: Any) {
    notifications.removeObserver(observer, name: didStopRunning, object: session)
}

// was interrupted
public func imageStreamWasInterrupedNotificationAdd(_ observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: wasInterrupted, object: session)
}
public func imageStreamWasInterrupedNotificationRemove(_ observer: Any) {
    notifications.removeObserver(observer, name: wasInterrupted, object: session)
}

// interruption ended
public func imageStreamInterruptionEndedNotificationAdd(_ observer: Any, calling selector: Selector) {
    notifications.addObserver(observer, selector: selector, name: interruptionEnded, object: session)
}
public func imageStreamInterruptionEndedNotificationRemove(_ observer: Any) {
    notifications.removeObserver(observer, name: interruptionEnded, object: session)
}
