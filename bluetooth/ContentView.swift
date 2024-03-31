//
//  ContentView.swift
//  bluetooth
//
//  Created by Jiahao Chen on 2024-03-31.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var service = BluetoothService()
    
    var body: some View {
        VStack {
            Text(service.peripheralStatus.rawValue)
                .font(.title)
            Text("\(service.humidityValue)")
                .font(.largeTitle)
                .fontWeight(.heavy)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
