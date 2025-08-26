@testable import cuid2
import Testing
import Foundation
import CryptoKit

@Suite("Config Mode Comparison")
struct FastComparisonTests {
    
    @Test("Speed comparison: Secure vs Fast")
    func compareImplementations() throws {
        let iterations = 10_000
        
        print("\n=== Performance Comparison: Secure vs Fast ===\n")
        
        // Warm up both implementations
        let secureGen = Cuid2Generator(config: .secure)
        let fastGen = Cuid2Generator(config: .fast)
        for _ in 0..<100 {
            _ = secureGen.generate()
            _ = fastGen.generate()
        }
        
        // Test Secure Implementation
        let secureStart = Date()
        for _ in 0..<iterations {
            _ = secureGen.generate()
        }
        let secureDuration = Date().timeIntervalSince(secureStart)
        
        // Test Fast Implementation
        let fastStart = Date()
        for _ in 0..<iterations {
            _ = fastGen.generate()
        }
        let fastDuration = Date().timeIntervalSince(fastStart)
        
        // Calculate metrics
        let secureThroughput = Double(iterations) / secureDuration
        let fastThroughput = Double(iterations) / fastDuration
        let speedup = secureDuration / fastDuration
        
        print("Secure Mode:")
        print("  Time: \(String(format: "%.2f", secureDuration * 1000))ms")
        print("  Throughput: \(Int(secureThroughput)) IDs/sec")
        print("  Latency: \(String(format: "%.2f", secureDuration / Double(iterations) * 1_000_000))μs per ID")
        print("")
        print("Fast Mode:")
        print("  Time: \(String(format: "%.2f", fastDuration * 1000))ms")
        print("  Throughput: \(Int(fastThroughput)) IDs/sec")
        print("  Latency: \(String(format: "%.2f", fastDuration / Double(iterations) * 1_000_000))μs per ID")
        print("")
        print("🚀 Speedup: \(String(format: "%.1f", speedup))x faster")
        print("")
        
        #expect(fastDuration < secureDuration, "Fast mode should be faster")
    }
    
    @Test("Cold start comparison")
    func compareColdStart() throws {
        print("\n=== Cold Start Comparison ===\n")
        
        var secureColdStarts: [TimeInterval] = []
        var fastColdStarts: [TimeInterval] = []
        
        for _ in 0..<50 {
            // Secure cold start
            let secureStart = Date()
            let secureGen = Cuid2Generator(config: .secure)
            _ = secureGen.generate()
            secureColdStarts.append(Date().timeIntervalSince(secureStart))
            
            // Fast cold start
            let fastStart = Date()
            let fastGen = Cuid2Generator(config: .fast)
            _ = fastGen.generate()
            fastColdStarts.append(Date().timeIntervalSince(fastStart))
        }
        
        let avgSecure = secureColdStarts.reduce(0, +) / Double(secureColdStarts.count)
        let avgFast = fastColdStarts.reduce(0, +) / Double(fastColdStarts.count)
        
        print("Secure mode cold start: \(String(format: "%.2f", avgSecure * 1000))ms avg")
        print("Fast mode cold start: \(String(format: "%.2f", avgFast * 1000))ms avg")
        print("🚀 Cold start speedup: \(String(format: "%.1f", avgSecure / avgFast))x faster")
    }
    
    @Test("Batch generation comparison")
    func compareBatchGeneration() throws {
        let batchSize = 10_000
        
        print("\n=== Batch Generation Comparison ===\n")
        
        let secureGen = Cuid2Generator(config: .secure)
        let fastGen = Cuid2Generator(config: .fast)
        
        // Secure batch
        let secureStart = Date()
        let secureBatch = secureGen.generate(times: batchSize)
        let secureDuration = Date().timeIntervalSince(secureStart)
        
        // Fast batch
        let fastStart = Date()
        let fastBatch = fastGen.generate(times: batchSize)
        let fastDuration = Date().timeIntervalSince(fastStart)
        
        print("Secure batch (\(batchSize) IDs): \(String(format: "%.2f", secureDuration * 1000))ms")
        print("Fast batch (\(batchSize) IDs): \(String(format: "%.2f", fastDuration * 1000))ms")
        print("🚀 Batch speedup: \(String(format: "%.1f", secureDuration / fastDuration))x faster")
        
        #expect(secureBatch.count == batchSize)
        #expect(fastBatch.count == batchSize)
    }
    
    @Test("Component performance breakdown")
    func componentBreakdown() throws {
        print("\n=== Component Performance Breakdown ===\n")
        
        let iterations = 1000
        
        // Test hash performance (SHA3 vs SHA256)
        let testData = Data("test_input_with_some_entropy_1234567890".utf8)
        
        // SHA3-512 (secure mode)
        let sha3Start = Date()
        for _ in 0..<iterations {
            _ = Cuid2Generator.hash(input: "test_input_with_some_entropy_1234567890")
        }
        let sha3Duration = Date().timeIntervalSince(sha3Start)
        
        // SHA256 (fast mode - test directly)
        let sha256Start = Date()
        for _ in 0..<iterations {
            _ = SHA256.hash(data: testData)
        }
        let sha256Duration = Date().timeIntervalSince(sha256Start)
        
        print("Hashing Performance (\(iterations) iterations):")
        print("  SHA3-512 + BigInt: \(String(format: "%.2f", sha3Duration * 1000))ms")
        print("  SHA256 (hardware): \(String(format: "%.2f", sha256Duration * 1000))ms")
        print("  Speedup: \(String(format: "%.1f", sha3Duration / sha256Duration))x")
        
        // Test validation performance
        let testId = "abcdefghij1234567890klmn"
        
        let valStart = Date()
        for _ in 0..<iterations * 10 {
            _ = isCuid2(id: testId)
        }
        let valDuration = Date().timeIntervalSince(valStart)
        
        print("\nValidation Performance (\(iterations * 10) iterations):")
        print("  Time: \(String(format: "%.2f", valDuration * 1000))ms")
    }
    
    @Test("Memory efficiency test")
    func memoryEfficiency() throws {
        print("\n=== Memory Efficiency Test ===\n")
        
        let iterations = 100_000
        
        // Measure time for many allocations (proxy for memory pressure)
        let secureGen = Cuid2Generator(config: .secure)
        let secureStart = Date()
        for _ in 0..<iterations {
            _ = secureGen.generate()
        }
        let secureDuration = Date().timeIntervalSince(secureStart)
        
        let fastGen = Cuid2Generator(config: .fast)
        let fastStart = Date()
        for _ in 0..<iterations {
            _ = fastGen.generate()
        }
        let fastDuration = Date().timeIntervalSince(fastStart)
        
        print("\(iterations) IDs generated:")
        print("  Secure: \(String(format: "%.2f", secureDuration))s")
        print("  Fast: \(String(format: "%.2f", fastDuration))s")
        print("  Memory efficiency improvement: \(String(format: "%.1f", secureDuration / fastDuration))x")
    }
    
    @Test("Concurrent generation safety")
    func concurrentSafety() async throws {
        print("\n=== Concurrent Safety Test ===\n")
        
        let fastGen = Cuid2Generator(config: .fast)
        let tasksCount = 10
        let idsPerTask = 1000
        
        let start = Date()
        
        let results = await withTaskGroup(of: [String].self) { group in
            for _ in 0..<tasksCount {
                group.addTask {
                    var ids: [String] = []
                    for _ in 0..<idsPerTask {
                        ids.append(fastGen.generate())
                    }
                    return ids
                }
            }
            
            var allIds: [String] = []
            for await taskIds in group {
                allIds.append(contentsOf: taskIds)
            }
            return allIds
        }
        
        let duration = Date().timeIntervalSince(start)
        let uniqueCount = Set(results).count
        
        print("Generated \(results.count) IDs across \(tasksCount) concurrent tasks")
        print("Unique IDs: \(uniqueCount)")
        print("Time: \(String(format: "%.2f", duration * 1000))ms")
        print("Throughput: \(Int(Double(results.count) / duration)) IDs/sec")
        
        #expect(uniqueCount == results.count, "All IDs should be unique")
    }
    
    @Test("Default config is fast")
    func testDefaultConfig() throws {
        // Default should be fast
        let defaultGen = Cuid2Generator()
        let explicitFastGen = Cuid2Generator(config: .fast)
        
        // Both should generate similarly performing IDs
        let defaultStart = Date()
        for _ in 0..<1000 {
            _ = defaultGen.generate()
        }
        let defaultTime = Date().timeIntervalSince(defaultStart)
        
        let fastStart = Date()
        for _ in 0..<1000 {
            _ = explicitFastGen.generate()
        }
        let fastTime = Date().timeIntervalSince(fastStart)
        
        // Should be within 20% of each other (accounting for variance)
        let ratio = defaultTime / fastTime
        print("Default vs explicit fast ratio: \(String(format: "%.2f", ratio))")
        #expect(ratio > 0.8 && ratio < 1.2, "Default should perform like fast mode")
    }
}