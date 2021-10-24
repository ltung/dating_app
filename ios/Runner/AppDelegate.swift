import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Config for place_picker plugin to use the Passport feature!
    // Add your iOS API KEY for Google MAPS 
    // Get your it from your Google Cloud Platform Developer Account
    // Link: https://console.cloud.google.com/apis/credentials
    GMSServices.provideAPIKey("YOUR iOS API KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
