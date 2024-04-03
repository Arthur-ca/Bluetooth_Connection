//
//  ContentView.swift
//  bluetooth
//
//  Created by Jiahao Chen on 2024-03-31.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    
    @State var service = BluetoothService.shared
    
    var body: some View {
        VStack {
            Text(service.peripheralStatus.rawValue)
                .font(.title)
            Text("\(service.humidityValue)")
                .font(.largeTitle)
                .fontWeight(.heavy)
            Button{
                toggleBluetooth()
            } label: {
                VStack{
                    Image(systemName: "sun.max")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                        .padding()
                    Text("Toggle Sensor")
                }
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .padding()
    }
    
    func toggleBluetooth() {
        if BluetoothService.shared.peripheralStatus == .connected {
            let commandByte: UInt8 = 0x01 // The command in byte form
            let data = Data([commandByte]) // Creating Data from the byte
            guard let char = BluetoothService.shared.sendCharacteristic else {
                print("Could not find command characteristic")
                return
            }
            BluetoothService.shared.sensorPeripheral?.writeValue(data, for: char, type: .withResponse)
            BluetoothService.shared.peripheralStatus = .disconnected
            BluetoothService.shared.humidityValue = ""
        }
        else if BluetoothService.shared.peripheralStatus == .disconnected {
            let commandByte: UInt8 = 0x02 // The command in byte form
            let data = Data([commandByte]) // Creating Data from the byte
            guard let char = BluetoothService.shared.sendCharacteristic else {
                print("Could not find command characteristic")
                return
            }
            BluetoothService.shared.sensorPeripheral?.writeValue(data, for: char, type: .withResponse)
            BluetoothService.shared.peripheralStatus = .connected
        }
    }
}

#Preview {
    ContentView()
}
