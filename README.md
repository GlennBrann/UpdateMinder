# UpdateMinder

UpdateMinder is a Swift Package for easily managing app update prompts. It provides a seamless way to prompt users for mandatory and optional updates based on the app version.

## Features

- Automatic version comparison to determine if an update is needed.
- Customizable alerts for optional updates.
- modal presentation for mandatory updates with customizable SwiftUI views. (formSheet) (disabled swipe to dismiss)

## Installation

To install UpdateMinder, you can use Swift Package Manager. Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/GlennBrann/UpdateMinder.git", .upToNextMajor(from: "1.0.0"))
]
```

## Usage

### Configuration

Configure `UpdateMinder` with the appropriate settings for your app. 


1. You can load via a json config file i.e via firebase remote config
```
{
    "latestVersion": "2.0.0",
    "isMandatory": true,
    "isNonMandatoryAlertVisible": true,
    "appStoreID": "123456",
    "updateMessage": "Exciting new features are available in version 2.0.0!",
    "alertTitle": "Important Update!",
    "alertMessage": "Please update to version 2.0.0 to continue using the app.",
    "alertCTA": "Update now"
}
```

### Checking for Updates 
To check for updates and present the update prompt:

```
let config = loadJsonConfig(filename: "AppUpdateConfig")

.task {
    await UpdateMinder.shared.checkForUpdates(
        withConfig: config
    )
}
```

### Passing a custom Mandatory Update View

```
let config = loadJsonConfig(filename: "AppUpdateConfig")

.task {
    await UpdateMinder.shared.checkForUpdates(
        withConfig: config,
        customView: {
             VStack {
                Text("Update available")
             }
        }
    )
}
```

