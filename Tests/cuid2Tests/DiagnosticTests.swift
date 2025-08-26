@testable import cuid2
import Testing
import Foundation

@Suite("Diagnostic Tests")
struct DiagnosticTests {
    
    @Test("ProcessInfo environment access timing")
    func processInfoTiming() throws {
        // Test ProcessInfo access separately
        let start1 = Date()
        let pid = ProcessInfo.processInfo.processIdentifier
        let pidDuration = Date().timeIntervalSince(start1)
        print("ProcessInfo.processIdentifier: \(pidDuration * 1000)ms")
        
        let start2 = Date()
        let hostname = ProcessInfo.processInfo.hostName
        let hostnameDuration = Date().timeIntervalSince(start2)
        print("ProcessInfo.hostName: \(hostnameDuration * 1000)ms")
        
        let start3 = Date()
        let env = ProcessInfo.processInfo.environment
        let envDuration = Date().timeIntervalSince(start3)
        print("ProcessInfo.environment: \(envDuration * 1000)ms (keys: \(env.count))")
        
        let start4 = Date()
        let envKeys = ProcessInfo.processInfo.environment.keys.joined()
        let envJoinDuration = Date().timeIntervalSince(start4)
        print("Environment.keys.joined(): \(envJoinDuration * 1000)ms (length: \(envKeys.count))")
        
        // Test the full fingerprint creation
        let start5 = Date()
        let fingerprint = Cuid2Generator.createFingerprint()
        let fingerprintDuration = Date().timeIntervalSince(start5)
        print("Full createFingerprint(): \(fingerprintDuration * 1000)ms")
    }
    
    @Test("Step-by-step ID generation timing")
    func stepByStepTiming() throws {
        print("\n=== Step-by-step ID Generation Timing ===\n")
        
        // Step 1: Create counter
        let counterStart = Date()
        let counter = Cuid2SessionCounter()
        let counterDuration = Date().timeIntervalSince(counterStart)
        print("1. Create counter: \(counterDuration * 1000)ms")
        
        // Step 2: Create entropy
        let entropyStart = Date()
        let salt = Cuid2Generator.createEntropy(length: 24)
        let entropyDuration = Date().timeIntervalSince(entropyStart)
        print("2. Create entropy: \(entropyDuration * 1000)ms")
        
        // Step 3: Create fingerprint (the suspected bottleneck)
        let fingerprintStart = Date()
        let fingerprint = Cuid2Generator.createFingerprint()
        let fingerprintDuration = Date().timeIntervalSince(fingerprintStart)
        print("3. Create fingerprint: \(fingerprintDuration * 1000)ms")
        
        // Step 4: Create generator with pre-computed values
        let generatorStart = Date()
        let generator = Cuid2Generator(counter: counter, fingerprint: fingerprint)
        let generatorDuration = Date().timeIntervalSince(generatorStart)
        print("4. Create generator (with pre-computed): \(generatorDuration * 1000)ms")
        
        // Step 5: Generate first ID
        let firstIdStart = Date()
        let firstId = generator.generate()
        let firstIdDuration = Date().timeIntervalSince(firstIdStart)
        print("5. Generate first ID: \(firstIdDuration * 1000)ms")
        
        // Step 6: Generate second ID (warm)
        let secondIdStart = Date()
        let secondId = generator.generate()
        let secondIdDuration = Date().timeIntervalSince(secondIdStart)
        print("6. Generate second ID: \(secondIdDuration * 1000)ms")
        
        print("\nTotal cold start: \(((counterDuration + entropyDuration + fingerprintDuration + generatorDuration + firstIdDuration) * 1000))ms")
        print("IDs generated: \(firstId), \(secondId)")
    }
    
    @Test("Fingerprint components breakdown")
    func fingerprintComponentsBreakdown() throws {
        print("\n=== Fingerprint Components Breakdown ===\n")
        
        // Get ProcessInfo data
        let pidStart = Date()
        let pid = String(ProcessInfo.processInfo.processIdentifier)
        let pidDuration = Date().timeIntervalSince(pidStart)
        
        let hostnameStart = Date()
        let hostname = ProcessInfo.processInfo.hostName
        let hostnameDuration = Date().timeIntervalSince(hostnameStart)
        
        let envStart = Date()
        let env = ProcessInfo.processInfo.environment.keys.joined()
        let envDuration = Date().timeIntervalSince(envStart)
        
        print("ProcessInfo gathering:")
        print("  PID (\(pid)): \(pidDuration * 1000)ms")
        print("  Hostname (\(hostname)): \(hostnameDuration * 1000)ms")
        print("  Environment (length: \(env.count)): \(envDuration * 1000)ms")
        
        // Test concatenation
        let concatStart = Date()
        let data = pid + hostname + env
        let concatDuration = Date().timeIntervalSince(concatStart)
        print("  Concatenation (length: \(data.count)): \(concatDuration * 1000)ms")
        
        // Test entropy generation
        let entropyStart = Date()
        let entropy = Cuid2Generator.createEntropy(length: 32)
        let entropyDuration = Date().timeIntervalSince(entropyStart)
        print("\nEntropy generation: \(entropyDuration * 1000)ms")
        
        // Test hashing
        let hashStart = Date()
        let hashed = Cuid2Generator.hash(input: data + entropy)
        let hashDuration = Date().timeIntervalSince(hashStart)
        print("SHA3-512 hashing: \(hashDuration * 1000)ms")
        
        // Test prefix
        let prefixStart = Date()
        let result = String(hashed.prefix(32))
        let prefixDuration = Date().timeIntervalSince(prefixStart)
        print("String prefix: \(prefixDuration * 1000)ms")
        
        print("\nTotal: \((pidDuration + hostnameDuration + envDuration + concatDuration + entropyDuration + hashDuration + prefixDuration) * 1000)ms")
    }
    
    @Test("SwiftUI Preview simulation")
    func swiftUIPreviewSimulation() throws {
        print("\n=== SwiftUI Preview Simulation ===\n")
        
        // Simulate cold start in preview context
        let fullStart = Date()
        
        // This is what would happen in a SwiftUI preview
        let generator = Cuid2Generator()
        let id = generator.generate()
        
        let fullDuration = Date().timeIntervalSince(fullStart)
        
        print("Full cold start time: \(fullDuration * 1000)ms")
        print("Generated ID: \(id)")
        
        // Try multiple times to see if there's variance
        print("\nMultiple cold starts:")
        for i in 1...5 {
            let start = Date()
            let gen = Cuid2Generator()
            let _ = gen.generate()
            let duration = Date().timeIntervalSince(start)
            print("  Attempt \(i): \(duration * 1000)ms")
        }
    }
}