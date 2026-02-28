//
//  ViewsComponentSoundWaveView.swift
//  Swift Student Challenge Real
//
//  Created by Luis on 10/02/26.
//

//
//  SoundWaveView.swift
//  Swift Student Challenge app
//
//  Created by LuisRosales on 05/01/26.
//

import SwiftUI
import AVFoundation
import Accelerate
import Charts

enum Constants {
    static let sampleAmount: Int = 200
    
    //Decrease to have a more crowded chart
    static let downsampleFactor = 8
    
    static let magnitudeLimit: Float = 100
}


struct SoundWaveView: View {
    // Each view gets its own monitor instance (not a singleton)
    @State private var monitor = AudioWaveFormMonitor()
    // Gradients for the chart
    private let chartGradient = LinearGradient(
        gradient: Gradient(colors: [.blue, .purple, .red]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        Chart(monitor.downsampledMagnitudes.indices, id: \ .self) { index in
            // 2. The LineMark
            LineMark(
                // a. frequency bins adjusted by Constants.downsampleFactor to spread points apart
                x: .value("Frequency", index * Constants.downsampleFactor),
                // b. the magnitude (intensity) of each frequency
                y: .value("Magnitude", monitor.downsampledMagnitudes[index])
            )
            // 3. Smoothing the curves
            .interpolationMethod(.catmullRom)
            
            // The line style
            .lineStyle(StrokeStyle(lineWidth: 3))
            // The color
            .foregroundStyle(chartGradient)
        }
        .chartYScale(domain: 0...max(monitor.fftMagnitudes.max() ?? 0, Constants.magnitudeLimit))
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 300)
        .padding()
        // 3. Smoothing the curves
        .animation(.easeOut, value: monitor.downsampledMagnitudes)
        .task {
            await monitor.startMonitoring()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
        
        
    }
    
    @MainActor
    @Observable
    final class AudioWaveFormMonitor {
        // Provide access to the microphone stream
        private var audioEngine = AVAudioEngine()
        
        var fftMagnitudes = [Float](repeating: 0, count: Constants.sampleAmount)
        
        var downsampledMagnitudes: [Float] {
            fftMagnitudes.lazy.enumerated().compactMap {
                index, value in index.isMultiple(of: Constants.downsampleFactor) ? value : nil
            }
        }
        private let bufferSize = 8192
        private var fftSetup: OpaquePointer?
        var isMonitoring = false
        
        // Continuation to allow cancelling the stream
        private var streamContinuation: AsyncStream<[Float]>.Continuation?
        
        init() {}
        
        func startMonitoring() async {
            // Request microphone permission first
            let authorized = await AVAudioApplication.requestRecordPermission()
            guard authorized else {
                print("Microphone permission denied")
                return
            }
            
            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.inputFormat(forBus: 0)
            fftSetup = vDSP_DFT_zop_CreateSetup(nil, UInt(self.bufferSize), .FORWARD)
            
            let audioStream = AsyncStream<[Float]> { continuation in
                // Store continuation so we can finish it from stopMonitoring()
                self.streamContinuation = continuation
                
                // Clean up when stream is cancelled or finished
                continuation.onTermination = { @Sendable _ in
                    Task { @MainActor in
                        self.cleanupAudioEngine()
                    }
                }
                
                inputNode.installTap(onBus: 0, bufferSize: UInt32(bufferSize), format: inputFormat) { @Sendable buffer, _ in
                    let channelData = buffer.floatChannelData?[0]
                    let frameCount = Int(buffer.frameLength)
                    
                    // Convert it into a Float array
                    let floatData = Array(UnsafeBufferPointer(start: channelData, count: frameCount))
                    
                    // Yield into the stream
                    continuation.yield(floatData)
                }
            }
            
            do {
                // 1. Start the audioEngine
                try audioEngine.start()
                isMonitoring = true
            } catch {
                print("Error starting audio engine:\(error.localizedDescription)")
                return
            }
            
            // 3. Retrieving the data from the audioStream
            for await floatData in audioStream {
                // 4. For each buffer, compute the FFT and store the results
                self.fftMagnitudes = await self.performFFT(data: floatData)
            }
            
        }
        
        func stopMonitoring() {
            // Finish the stream, which triggers onTermination cleanup
            streamContinuation?.finish()
            streamContinuation = nil
            isMonitoring = false
        }
        
        private func cleanupAudioEngine() {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            fftMagnitudes = [Float](repeating: 0, count: Constants.sampleAmount)
            
            if let setup = fftSetup {
                vDSP_DFT_DestroySetup(setup)
                fftSetup = nil
            }
        }
        
        func performFFT (data: [Float]) async -> [Float] {
            guard let setup = fftSetup else {
                return [Float](repeating: 0, count: Constants.sampleAmount)
            }
            
            var realIn = data
            var imagIn = [Float](repeating: 0, count: bufferSize)
            var realOut = [Float](repeating: 0, count: bufferSize)
            var imagOut = [Float](repeating: 0, count: bufferSize)
            
            var magnitudes = [Float](repeating: 0, count: Constants.sampleAmount)
            
            realIn.withUnsafeMutableBufferPointer { realInPtr in
                imagIn.withUnsafeMutableBufferPointer { imagInPtr in
                    realOut.withUnsafeMutableBufferPointer { realOutPtr in
                        imagOut.withUnsafeMutableBufferPointer { imagOutPtr in
                            // 2. Execute the Discrete Fourier Transform (DFT)
                            vDSP_DFT_Execute(setup, realInPtr.baseAddress!, imagInPtr.baseAddress!, realOutPtr.baseAddress!, imagOutPtr.baseAddress!)
                            
                            
                            // 3. Hold the DFT output
                            var complex = DSPSplitComplex(realp: realOutPtr.baseAddress!, imagp: imagOutPtr.baseAddress!)
                            // 4. Compute and save the magnitude of each frequency component
                            vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(Constants.sampleAmount))
                            
                        }
                    }
                }
            }
            
            // Zero out DC and low-frequency noise (first 10 bins)
            for i in 0..<10 {
                magnitudes[i] = 0
            }
            return magnitudes.map { min($0, Constants.magnitudeLimit) }
        }
    }
    
    
    
    
    
}

#Preview("Live Audio FFT Waveform") {
    SoundWaveView()
}
