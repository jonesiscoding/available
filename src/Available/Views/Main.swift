//
//  Main.swift
//  Available
//
//  Created by Aaron M Jones
//  Based on Barmaid Template (https://github.com/stevenselcuk/Barmaid)
//

import SwiftUI

struct Main: View {
    var delegate: AppDelegate = NSApp.delegate as! AppDelegate

    // UI Specific
    @State private var currentPage = 0

    var body: some View {
        PagerView(pageCount: 2, currentIndex: $currentPage) {
            VStack(alignment: .center, spacing: 10) {
                Spacer()
                Text("Available")
                    .help(Text("Available"))
                    .font(Font.system(size:30, design: .monospaced))
                    .padding(.bottom, 100)
                HStack {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .padding(.bottom, 20)
                .contentShape(Rectangle())
                .help(Text("App Settings"))
                .accessibility(hint: Text("On click navigates to settings section"))
                .onTapGesture {
                    withAnimation {
                        currentPage = 1
                    }
                }
            }

            VStack(alignment: .center, spacing: 10) {
                Spacer()
                HStack(alignment: .center, spacing: 30) {
                    HStack {
                        Image(systemName: "arrowshape.turn.up.left")
                        Text("Back")
                    }
                    .contentShape(Rectangle())
                    .help(Text("Return Main View"))
                    .accessibility(hint: Text("On click navigates to main section"))
                    .onTapGesture {
                        withAnimation {
                            currentPage = 0
                        }
                    }

                    HStack {
                        Image(systemName: "power")
                        Text("Quit App")
                    }
                    .contentShape(Rectangle())
                    .help(Text("Return Main View"))
                    .accessibility(hint: Text("On click navigates to main section"))
                    .onTapGesture {
                        delegate.quit()
                    }
                }.padding(.bottom, 20)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}
