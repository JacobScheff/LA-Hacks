//
//  ContentView.swift
//  LA Hacks
//
//  Created by Jacob Scheff on 4/24/26.
//

import SwiftUI

struct ContentView: View {
    @State private var mem: Int = 0;

    var body: some View {
        
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button("abc") {
                mem = os_proc_available_memory();
            }
            
            Text("Memory: \(mem)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
