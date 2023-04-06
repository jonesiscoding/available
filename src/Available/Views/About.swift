//
//  About.swift
//  Available
//
//  Created by Aaron M Jones
//  Based on Barmaid Template (https://github.com/stevenselcuk/Barmaid)
//

import Cocoa
import SwiftUI

struct AboutView: View {
    var nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject

    var body: some View {
        let version = nsObject as! String
        VStack(alignment: .center, spacing: 10) {
            VStack(alignment: .center) {
                Image("Available")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)

                Text("Available \(version)")
                    .bold()
                    .font(.title)
                    .padding(.vertical, 5.0)
                    .accessibility(hint: Text("Available \(version)"))

                Text("Created by Aaron M Jones")
                    .underline()
                    .onTapGesture {
                        let email = "https://github.com/jonesiscoding"
                        if let url = URL(string: email) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .accessibility(hint: Text("Available app, created by Aaron M Jones. Opens developers GitHub profile on click."))
            }
            .padding(.vertical, 10.0)
        }.padding(.horizontal, 10.0)
            .background(Color.clear)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
    }
}

class AboutWindowController {
    static func createWindow() {
        var windowRef: NSWindow
        windowRef = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 280),
            styleMask: [
                .titled,
                .closable,
                .borderless],
            backing: .buffered, defer: false)
        windowRef.contentView = NSHostingView(rootView: AboutView())
        windowRef.title = "About Available"
        windowRef.level = NSWindow.Level.screenSaver
        windowRef.isReleasedWhenClosed = false
        windowRef.makeKeyAndOrderFront(nil)
    }
}
