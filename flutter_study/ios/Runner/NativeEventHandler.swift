//
//  NativeEventHandler.swift
//  Runner
//
//  Created by huchu on 2025/8/16.
//


import Flutter

class NativeEventHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // 可以立即发送一条消息
        events("Native已准备好")
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    func sendMessageToFlutter(_ message: String) {
        eventSink?(message)
    }
}