# DownloadAndPlayVideoOffline-iOS
A simple iOS app with mvvm approach that allows users to download multiple videos simultaneously, store them locally, and play them offline using the system’s video player (AVPlayerViewController).

🚀 Features
List of videos displayed using UITableView.

Per video:

Download button (if not downloaded).

Real-time download progress.

Delete button (after download completion).

Retry button (if download fails) with error alert.

Offline support: Play downloaded videos without an internet connection.

Background downloading: Downloads continue even if the app goes into the background (partially supported).

Error handling with user-friendly alerts.

🛠️ Tech Stack
Language: Swift 5.7+

iOS Target: iOS 16+

UI: UIKit (UITableView, Custom Cells)

Downloads: URLSessionDownloadTask (Background Session Configuration)

Storage: FileManager (Documents Directory)

Playback: AVPlayerViewController

Architecture: MVVM (Model-View-ViewModel)

📦 Setup Instructions
Clone the repository:

bash
Copy
Edit
git clone https://github.com/sushil33558/DownloadAndPlayVideoOffline-iOS.git
Open the project in Xcode 14+.

Run on a device/simulator with iOS 16+.
