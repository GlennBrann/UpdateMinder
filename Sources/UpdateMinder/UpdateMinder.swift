/*
 * Copyright (c) 2024, Glenn Brannelly and UpdateMinder contributors. All rights reserved
 *
 * Licensed under BSD 3-Clause License.
 * https://opensource.org/licenses/BSD-3-Clause
 */

import Foundation
import SwiftUI

// Configuration struct for UpdateMinder
public struct UpdateMinderConfig: Codable {
    var latestVersion: String
    var isMandatory: Bool
    var isNonMandatoryAlertVisible: Bool?
    var appStoreID: String
    var updateMessage: String?
    var alertTitle: String?
    var alertMessage: String?
    var alertCTA: String?
    var alertCancel: String?
}

// Main class for handling app updates
public class UpdateMinder {
    public static let shared = UpdateMinder()
    
    // Private initializer to enforce singleton usage
    private init() { }
    
    /// Checks for updates based on the provided configuration.
    /// - Parameters:
    ///   - config: Configuration data for the update check.
    ///   - customViewProvider: Optional closure that provides a custom SwiftUI view for mandatory updates.
    public func checkForUpdates(
        withConfig config: UpdateMinderConfig,
        customView: (() -> any View)? = nil
    ) async {
        // Construct the URL for the App Store based on the appStoreID
        let appStoreURL = URL(string: "itms-apps://apple.com/app/id\(config.appStoreID)")
        
        // Ensure that the current version is less than the latest version
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              currentVersion.compare(config.latestVersion, options: .numeric) == .orderedAscending,
              let appStoreURL = appStoreURL else {
            return
        }
        
        await MainActor.run {
            // Get the top most view controller to present the update UI
            guard let topViewController = UIViewController.topMostViewController else { return }
            
            // Present a full-screen modal for mandatory updates
            if config.isMandatory {
                let viewToPresent = customView?() ?? MandatoryUpdateView(config: config)
                let hostingController = UIHostingController(rootView: AnyView(viewToPresent))
                hostingController.modalPresentationStyle = .formSheet
                hostingController.isModalInPresentation = true
                topViewController.present(hostingController, animated: true, completion: nil)
            } else if config.isNonMandatoryAlertVisible ?? true {
                // Present an alert for non-mandatory updates
                presentOptionalUpdateAlert(config: config, appStoreURL: appStoreURL, on: topViewController)
            }
        }
    }
    
    // Presents an alert for optional updates
    private func presentOptionalUpdateAlert(
        config: UpdateMinderConfig,
        appStoreURL: URL,
        on viewController: UIViewController
    ) {
        let title = config.alertTitle ?? "Update Available"
        let message = config.alertMessage ?? (config.updateMessage ?? "A new version of the app is available.")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: config.alertCTA, style: .default, handler: { _ in
            UIApplication.shared.open(appStoreURL)
        }))
        alertController.addAction(UIAlertAction(title: config.alertCancel ?? "Later", style: .cancel, handler: nil))
        viewController.present(alertController, animated: true, completion: nil)
    }
}

// Default view for presenting mandatory updates
private struct MandatoryUpdateView: View {
    @Environment(\.openURL) var openUrl
    
    let config: UpdateMinderConfig
    
    var configDescription: String {
        config.alertMessage ?? "Please update to version \(config.latestVersion) to continue using the app."
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text(config.alertTitle ?? "Important Update!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(configDescription)
                .font(.body)
            
            Button(config.alertCTA ?? "") {
                if let url = URL(string: "itms-apps://apple.com/app/id880731821") {
                    openUrl(url)
                }
            }
            .padding()
            .foregroundColor(.primary)
            .background(Capsule().fill(.secondary))
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
}

fileprivate extension UIViewController {
    static var topMostViewController: UIViewController? {
        guard let keyWindow = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .filter({ $0.isKeyWindow }).first else {
            return nil
        }
        
        var topController = keyWindow.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}
