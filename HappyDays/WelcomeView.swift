//
//  WelcomeView.swift
//  HappyDays
//
//  Created by Philipp on 08.08.20.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var permissionChecker: PermissionChecker

    var body: some View {
        VStack(spacing: 50) {
            Text(permissionChecker.helpText)
                .font(.title3)
                .multilineTextAlignment(.center)

            if permissionChecker.showOpenSettingsButton {
                Button(action: openSettings) {
                    Text("Open settings")
                        .font(.title3)
                }
            }

            Button(action: permissionChecker.requestPermissions) {
                Text("Continue")
                    .font(.title2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .navigationBarTitle(Text("Welcome"), displayMode: .inline)
    }

    private func openSettings() {
        let settingsUrl = URL(string:UIApplication.openSettingsURLString)!
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WelcomeView(permissionChecker: PermissionChecker())
        }
    }
}
