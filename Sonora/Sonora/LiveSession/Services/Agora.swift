//
//  Agora.swift
//  Sonora
//
//  Created by Nabiha Khalid on 16/11/26.
//

import Foundation
import Combine
import AgoraRtcKit

final class AgoraManager: NSObject, ObservableObject {
    private let appID = "e9a54e78c1954ced8c3cfe95b8bb3cfc"
    private var agoraKit: AgoraRtcEngineKit!

    @Published var remoteUID: UInt?

    override init() {
        super.init()

        agoraKit = AgoraRtcEngineKit.sharedEngine(
            withAppId: appID,
            delegate: self
        )

        agoraKit.enableVideo()
    }

    func joinChannel(
        channelName: String,
        token: String?
    ) {
        let options = AgoraRtcChannelMediaOptions()

        options.channelProfile = .communication
        options.clientRoleType = .broadcaster
        options.publishCameraTrack = true
        options.publishMicrophoneTrack = true
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = true

        agoraKit.joinChannel(
            byToken: token,
            channelId: channelName,
            uid: 0,
            mediaOptions: options
        )
    }

    func leaveChannel() {
        agoraKit.leaveChannel(nil)
        remoteUID = nil
    }

    func setupLocalVideo(view: UIView) {
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = 0
        canvas.view = view
        canvas.renderMode = .hidden

        agoraKit.setupLocalVideo(canvas)
        agoraKit.startPreview()
    }

    func setupRemoteVideo(uid: UInt, view: UIView) {
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = uid
        canvas.view = view
        canvas.renderMode = .hidden

        agoraKit.setupRemoteVideo(canvas)
    }
}

extension AgoraManager: AgoraRtcEngineDelegate {
    func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didJoinedOfUid uid: UInt,
        elapsed: Int
    ) {
        DispatchQueue.main.async {
            self.remoteUID = uid
        }
    }

    func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didOfflineOfUid uid: UInt,
        reason: AgoraUserOfflineReason
    ) {
        DispatchQueue.main.async {
            self.remoteUID = nil
        }
    }
}

