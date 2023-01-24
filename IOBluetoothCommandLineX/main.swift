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


class BluetoothDevices: NSObject, IOBluetoothRFCOMMChannelDelegate {

    private let classOfNothing:UInt32 = 2360324
    private var operationID = 1
    
    func connectToDevice(address: String, channelID: Int) {
        device = IOBluetoothDevice(addressString: address)

        // Open a connection to the device
        let resultConnection = device.openConnection()
        if resultConnection == kIOReturnSuccess {
            print("Connected to device")
        } else {
            print("Failed to connect to device")
        }

        // Open an RFCOMM channel to the device
        let resultRFCOMM = device.openRFCOMMChannelSync(&channel, withChannelID: 15, delegate: self)
        if resultRFCOMM == kIOReturnSuccess {
            print("Opened RFCOMM channel")
            ringBuds(ring: true)
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

    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        // Read data from the device
        let data = Data(bytes: dataPointer, count: dataLength)
        let string = String(data: data, encoding: .utf8)!
        print("Received data: \(string)")
    }

    func close() {
        // Close the RFCOMM channel and the connection to the device
        channel.close()
        device.closeConnection()
    }
    
  func pairedDevices() {
    print("Bluetooth devices:")
      let devices = IOBluetoothDevice.pairedDevices().filter{ $0 is IOBluetoothDevice }.map{ $0 as! IOBluetoothDevice };
      
      let nothingx = devices.filter{ $0.classOfDevice == classOfNothing }
      
    for device in nothingx {
        print("Name: \(device.name ?? "Unknown")")
        print("classOfDevice: \(device.classOfDevice)")
        print("addressString : \(device.addressString ?? "Unknown")")
        
//        device.openConnection() // Not required if already connected.

        print("Paired?: \(device.isPaired())")
        print("Connected?: \(device.isConnected())")
    }
  }
    

    func crc16(data: [UInt8]) -> [UInt8] {
        var num: UInt16 = 65535
        for i in 0..<data.count {
            num = num ^ UInt16(data[i])
            for _ in 0..<8 {
                num = ((num & 1) != 1) ? (num >> 1) : (num >> 1) ^ 0xA001
            }
        }
        return withUnsafeBytes(of: num, Array.init)
    }

    func ringBuds(ring: Bool){
//        var array = [UInt8](repeating: 0, count: 9);
        
//        operationID += 1;
//        array[7] = UInt8(operationID);
//        array[8] = ring ? 1 : 0;
//        array += crc16(data: array);
//        print(array.map { String(format: "%02x", $0) }.joined(separator: "-"));
        
        var byteArray = [UInt8(0x55), UInt8(0x60), UInt8(0x01), UInt8(0x02), UInt8(0xf0), UInt8(0x01), UInt8(0x00), UInt8(0x1b), UInt8(0x00), UInt8(0x54), UInt8(0x70)]
        
        send(data: &byteArray, data_count: UInt16(byteArray.count))
    }
}

var bt = BluetoothDevices()
bt.pairedDevices()
//bt.performSDPQuery(address: "2c-be-eb-04-b4-25")
//bt.ringBuds(ring: true)

var ns = NothingSearcher()
print("Device", ns.getDevice())
print("Service", ns.getService())
print("Connected",ns.isConnected())

bt.connectToDevice(address: "2c-be-eb-04-b4-25", channelID: Int(ns.getService().getRFCOMMChannelID(&channelID)))
