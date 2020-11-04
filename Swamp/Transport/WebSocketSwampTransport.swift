//
//  WebSocketTransport.swift
//  swamp
//
//  Created by Yossi Abraham on 18/08/2016.
//  Copyright © 2016 Yossi Abraham. All rights reserved.
//

import Foundation
import Starscream

open class WebSocketSwampTransport: SwampTransport, WebSocketDelegate {
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
            case .connected(let headers):
                print("websocket is connected: \(headers)")
                delegate?.swampTransportDidConnectWithSerializer(JSONSwampSerializer())
            case .disconnected(let reason, let code):
                print("websocket is disconnected: \(reason) with code: \(code)")
                delegate?.swampTransportDidDisconnect(nil, reason: reason)
            case .text(let string):
                print("Received text: \(string)")
                if let data = string.data(using: String.Encoding.utf8) {
                    self.websocketDidReceiveData(socket: socket, data: data)
                }
            case .binary(let data):
                print("Received data: \(data.count)")
                delegate?.swampTransportReceivedData(data)
            case .ping(_):
                break
            case .pong(_):
                break
            case .viabilityChanged(_):
                break
            case .reconnectSuggested(_):
                break
            case .cancelled:
                break
            case .error(let error):
                if let error = error {
                    delegate?.swampTransportDidDisconnect(error as NSError, reason: nil)
                }
            }
    }
    
    
    enum WebsocketMode {
        case binary, text
    }
    
    open var delegate: SwampTransportDelegate?
    let socket: WebSocket
    let mode: WebsocketMode
    
    fileprivate var disconnectionReason: String?
    
    public init(wsEndpoint: URL){
        var request = URLRequest(url: wsEndpoint)
        request.addValue("wamp.2.json", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        self.socket = WebSocket(request: request)
        self.mode = .text
        socket.delegate = self
    }
    
    // MARK: Transport
    
    open func connect() {
        self.socket.connect()
    }
    
    open func disconnect(_ reason: String) {
        self.disconnectionReason = reason
        self.socket.disconnect()
    }
    
    open func sendData(_ data: Data) {
        if self.mode == .text {
            self.socket.write(string: String(data: data, encoding: String.Encoding.utf8)!)
        } else {
            self.socket.write(data: data)
        }
    }
    
    // MARK: WebSocketDelegate
    
    open func websocketDidConnect(socket: WebSocket) {
        // TODO: Check which serializer is supported by the server, and choose self.mode and serializer
        delegate?.swampTransportDidConnectWithSerializer(JSONSwampSerializer())
    }
    
    open func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        delegate?.swampTransportDidDisconnect(error, reason: self.disconnectionReason)
    }
    
    open func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        if let data = text.data(using: String.Encoding.utf8) {
            self.websocketDidReceiveData(socket: socket, data: data)
        }
    }
    
    open func websocketDidReceiveData(socket: WebSocket, data: Data) {
        delegate?.swampTransportReceivedData(data)
    }
}
