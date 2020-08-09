//
//  ContentView.swift
//  HappyDays
//
//  Created by Philipp on 08.08.20.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var checker = PermissionChecker()

    var body: some View {
        NavigationView {
            if checker.requestAuthorization {
                WelcomeView(permissionChecker: checker)
            }
            else {
                MemoriesView()
            }
        }
        .onAppear() {
            checker.checkPermissions()
        }
        .accentColor(.orange)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
