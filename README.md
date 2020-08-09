# SwiftUI-HappyDays

This is "Happy Days", based on Paul Hudsons project in his book ["Advanced iOS Volume One"](https://www.hackingwithswift.com/store/advanced-ios-1).
Checkout his website [hackingwithswift.com](https://www.hackingwithswift.com) which has a lot of learning materials.


Happy Days: is an app that stores photos the user has selected, along with voice recordings recounting what’s in the picture.
To make it more interesting, it uses speech recognition to transcribe the user's voice recordings, then store that transcription in Core Spotlight.

And as I like SwiftUI, I'm rewriting the project using SwiftUI instead of UIKit.

## Current state of Happy Days

- Basic UI with search field and scrolling grid view to show the thumbnail of the memories
- Adding photos from the photo library using `UIImagePickerController`

