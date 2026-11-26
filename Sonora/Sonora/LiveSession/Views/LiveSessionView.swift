import SwiftUI
import UIKit

struct LiveSessionView: View {
    let session: Session

    @StateObject private var agoraManager = AgoraManager()

    private var channelName: String {
        "sonora-\(session.id)"
    }
    
    agoraManager.joinChannel(
        channelName: channelName,
        token: nil
    )

    var body: some View {
        AppLayout {
            VStack(alignment: .leading, spacing: 20) {
                Text("Practice session")
                    .font(.title2.bold())

                Text("Your video")
                    .font(.headline)

                AgoraVideoView { view in
                    agoraManager.setupLocalVideo(view: view)
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Partner's video")
                    .font(.headline)

                if let remoteUID = agoraManager.remoteUID {
                    AgoraVideoView { view in
                        agoraManager.setupRemoteVideo(
                            uid: remoteUID,
                            view: view
                        )
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text("Waiting for your partner to join...")
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            agoraManager.joinChannel(
                channelName: channelName,
                token: token
            )
        }
        .onDisappear {
            agoraManager.leaveChannel()
        }
    }
}

struct AgoraVideoView: UIViewRepresentable {
    let setup: (UIView) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        DispatchQueue.main.async {
            setup(view)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
