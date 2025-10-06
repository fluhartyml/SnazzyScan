//  ContentView.swift
//  SnazzyScan
//
//  Created by Michael Fluharty on 2025-10-05 18:59
//

import SwiftUI

struct ContentView: View {
    @State private var showScanner = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                Text("SnazzyScan")
                    .font(.largeTitle)
                    .bold()
                Text("Tap the button to scan a document")
                    .foregroundColor(.gray)
                Button {
                    showScanner = true
                } label: {
                    Label("Scan Document", systemImage: "camera")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("SnazzyScan")
            .sheet(isPresented: $showScanner) {
                DocumentScanner()
            }
        }
    }
}

#Preview {
    ContentView()
}
