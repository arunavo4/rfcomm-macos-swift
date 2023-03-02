//
//  main.swift
//  IOBluetoothCommandLineX
//
//  Created by Arunavo Ray on 24/01/23.
//

import Foundation
import IOBluetooth
// See https://developer.apple.com/reference/iobluetooth/iobluetoothdevice
// for API details.
let semaphore = DispatchSemaphore(value: 0)

var device: IOBluetoothDevice!
var channel: IOBluetoothRFCOMMChannel!
var channelID: BluetoothRFCOMMChannelID!

// 0x 55 60 01 02 f0 01 00 00 00
var initialArray: [UInt8] = [0x55, 0x60, 0x01, 0x02, 0xf0, 0x01, 0x00, 0x00, 0x00]

class BluetoothDevices: NSObject, IOBluetoothRFCOMMChannelDelegate {

    private let classOfNothing:UInt32 = 2360324
    private var operationID = 1
    private let crc = CRC16()
    
    func connectToDevice(address: String, channelID: UInt8) {
        device = IOBluetoothDevice(addressString: address)

        // Open a connection to the device
        let resultConnection = device.openConnection()
        if resultConnection == kIOReturnSuccess {
            print("Connected to device")
        } else {
            print("Failed to connect to device")
        }

        // Open an RFCOMM channel to the device
        let resultRFCOMM = device.openRFCOMMChannelSync(&channel, withChannelID: channelID, delegate: self)
        if resultRFCOMM == kIOReturnSuccess {
            print("Opened RFCOMM channel")
            // Start sending commands
        } else {
            print("Failed to open RFCOMM channel")
        }
        
        
    }

    func send(data: UnsafeMutableRawPointer, data_count: UInt16) {
        // Write data to the device
        let result = channel.writeSync(data, length: data_count)
        if result == kIOReturnSuccess {
            print("Sent data")
        } else {
            print("Failed to send data")
        }
    }

    func close() {
        // Close the RFCOMM channel and the connection to the device
        channel.close()
        device.closeConnection()
    }
    
    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        // Read data from the device
        print("rfcommChannelData called")
        print("dataLength = \(dataLength)")
        let data = Data(bytes: dataPointer, count: dataLength)
        let string = String(data: data, encoding: .utf8)!
        print("Received data: \(string)")
    }
    
    func rfcommChannelControlSignalsChanged(_ rfcommChannel: IOBluetoothRFCOMMChannel!)
    {
        print("rfcommChannelControlSignalsChanged")
    }
    
    func rfcommChannelFlowControlChanged(_ rfcommChannel: IOBluetoothRFCOMMChannel!)
    {
        print("rfcommChannelFlowControlChanged")
    }
    
    private func rfcommChannelWriteComplete(rfcommChannel: IOBluetoothRFCOMMChannel!, refcon: UnsafeMutableRawPointer, status error: IOReturn)
    {
        print("rfcommChannelWriteComplete")
    }
    
    func rfcommChannelQueueSpaceAvailable(_ rfcommChannel: IOBluetoothRFCOMMChannel!)
    {
        print("rfcommChannelQueueSpaceAvailable")
    }
    
  func pairedDevices() {
    print("Bluetooth devices:")
      let devices = IOBluetoothDevice.pairedDevices().filter{ $0 is IOBluetoothDevice }.map{ $0 as! IOBluetoothDevice };
      
      let nothingx = devices.filter{ $0.classOfDevice == classOfNothing }
      
    for device in nothingx {
        print("Name: \(device.name ?? "Unknown")")
        print("classOfDevice: \(device.classOfDevice)")
        print("addressString : \(device.addressString ?? "Unknown")")

        print("Paired?: \(device.isPaired())")
        print("Connected?: \(device.isConnected())")
    }
  }

    func ringBuds(ring: Bool){
        var byteArray: [UInt8] = initialArray
        operationID += 1;   // This is used to Keep track for recovery data

        byteArray[7] = UInt8(operationID);
        byteArray[8] = ring ? 1 : 0;
        byteArray += crc.getCrc(byteArray)
        print(byteArray.map { String(format: "%02x", $0) }.joined(separator: "-"));
        
        send(data: &byteArray, data_count: UInt16(byteArray.count))
    }
    
    func getBattery() {
        var byteArray: [UInt8] = initialArray
        operationID += 1;   // This is used to Keep track for recovery data
        
        byteArray[7] = UInt8(operationID);
        byteArray += crc.getCrc(byteArray)
        print(byteArray.map { String(format: "%02x", $0) }.joined(separator: "-"));
        
        send(data: &byteArray, data_count: UInt16(byteArray.count))
    }
    
    func getANC() {
        var byteArray: [UInt8] = [0x55, 0x60, 0x01, 0x02, 0xf0, 0x01, 0x00, 0x00]
        operationID += 1;   // This is used to Keep track for recovery data
        
        byteArray[7] = UInt8(operationID);
        byteArray += crc.getCrc(byteArray)
        print(byteArray.map { String(format: "%02x", $0) }.joined(separator: "-"));
        
        send(data: &byteArray, data_count: UInt16(byteArray.count))
    }
}

while true {
    let bt = BluetoothDevices()
    let ns = NothingSearcher()
    
    print("\nMENU")
    print("1. Display Paired Devices")
    print("2. Search for Nothing Device")
    print("3. Connect RFCOMM")
    print("4. Start Ringing Buds")
    print("5. Stop Ringing Buds")
    print("6. Disconnect")
    print("7. Exit program")
    print("8. Get Battery")
    print("9. Get ANC")
    
    
    print("Enter your option:")
    let option = readLine()!
    switch option {
        case "1":
            bt.pairedDevices()
            
        case "2":
            print("Device", ns.getDevice())
            print("Service", ns.getService())
            print("Connected",ns.isConnected())
            
        case "3":
//            bt.connectToDevice(address: "2c-be-eb-04-b4-25", channelID: Int(ns.getService().getRFCOMMChannelID(&channelID)))
            bt.connectToDevice(address: "2c-be-eb-04-b4-25", channelID: 15)
            
        case "4":
            bt.ringBuds(ring: true)
            
        case "5":
            bt.ringBuds(ring: false)

        case "6":
            bt.close()
            
        case "7":
            print("Exit!")
            exit(0)
            
        case "8":
            bt.getBattery()
            
        case "9":
            bt.getANC()
    default:
        print("Invalid option. Please try again")
    }
}




