@testable import cuid2
import Testing
import Foundation

@Suite("Performance Benchmarks")
struct PerformanceTests {
    
    // MARK: - Single ID Generation
    
    @Test("Single ID generation baseline")
    func singleIDGenerationPerformance() throws {
        let generator = Cuid2Generator()
        let iterations = 10_000
        
        let start = Date()
        for _ in 0..<iterations {
            _ = generator.generate()
        }
        let duration = Date().timeIntervalSince(start)
        
        let throughput = Double(iterations) / duration
        print("Single ID: \(Int(throughput)) IDs/sec, \(duration * 1000 / Double(iterations))ms per ID")
        
        #expect(duration < 2.0, "Should generate 10k IDs in under 2 seconds")
    }
    
    @Test("ID generation with various lengths")
    func customLengthPerformance() throws {
        let configs: [(length: Int, iterations: Int)] = [
            (8, 10_000),
            (24, 10_000),
            (64, 5_000),
            (98, 2_000)
        ]
        
        for (length, iterations) in configs {
            let generator = Cuid2Generator(length: length)
            
            let start = Date()
            for _ in 0..<iterations {
                _ = generator.generate()
            }
            let duration = Date().timeIntervalSince(start)
            
            let throughput = Double(iterations) / duration
            print("Length \(length): \(Int(throughput)) IDs/sec")
        }
    }
    
    // MARK: - Batch Generation
    
    @Test("Batch generation performance")
    func batchGenerationPerformance() throws {
        let generator = Cuid2Generator()
        let batchSizes = [100, 1000, 10_000]
        
        for size in batchSizes {
            let start = Date()
            let ids = generator.generate(times: size)
            let duration = Date().timeIntervalSince(start)
            
            let throughput = Double(size) / duration
            print("Batch \(size): \(Int(throughput)) IDs/sec, \(duration * 1000)ms total")
            
            #expect(ids.count == size)
        }
    }
    
    @Test("Batch vs single generation comparison")
    func batchVsSingleComparison() throws {
        let generator = Cuid2Generator()
        let iterations = 5_000
        
        // Single generation
        let singleStart = Date()
        var singleIds: [String] = []
        for _ in 0..<iterations {
            singleIds.append(generator.generate())
        }
        let singleDuration = Date().timeIntervalSince(singleStart)
        
        // Batch generation
        let batchStart = Date()
        let batchIds = generator.generate(times: iterations)
        let batchDuration = Date().timeIntervalSince(batchStart)
        
        let speedup = singleDuration / batchDuration
        print("Batch is \(String(format: "%.2f", speedup))x faster than single generation")
        print("Single: \(singleDuration * 1000)ms, Batch: \(batchDuration * 1000)ms")
        
        #expect(batchIds.count == iterations)
        #expect(singleIds.count == iterations)
    }
    
    // MARK: - Cold Start Performance
    
    @Test("Cold start - first ID generation")
    func coldStartPerformance() throws {
        let iterations = 100
        var durations: [TimeInterval] = []
        
        for _ in 0..<iterations {
            let start = Date()
            let generator = Cuid2Generator()
            _ = generator.generate()
            let duration = Date().timeIntervalSince(start)
            durations.append(duration)
        }
        
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let minDuration = durations.min() ?? 0
        let maxDuration = durations.max() ?? 0
        
        print("Cold start (init + first ID):")
        print("  Average: \(avgDuration * 1000)ms")
        print("  Min: \(minDuration * 1000)ms")
        print("  Max: \(maxDuration * 1000)ms")
    }
    
    @Test("Warm vs Cold generation comparison")
    func warmVsColdComparison() throws {
        // Cold: Create generator and generate first ID
        var coldDurations: [TimeInterval] = []
        for _ in 0..<100 {
            let start = Date()
            let generator = Cuid2Generator()
            _ = generator.generate()
            coldDurations.append(Date().timeIntervalSince(start))
        }
        
        // Warm: Use existing generator for subsequent IDs
        let generator = Cuid2Generator()
        _ = generator.generate() // warm up
        
        var warmDurations: [TimeInterval] = []
        for _ in 0..<100 {
            let start = Date()
            _ = generator.generate()
            warmDurations.append(Date().timeIntervalSince(start))
        }
        
        let avgCold = coldDurations.reduce(0, +) / Double(coldDurations.count)
        let avgWarm = warmDurations.reduce(0, +) / Double(warmDurations.count)
        
        print("Cold (init + first ID): \(avgCold * 1000)ms avg")
        print("Warm (subsequent IDs): \(avgWarm * 1000)ms avg")
        print("Cold start overhead: \(String(format: "%.1f", avgCold / avgWarm))x slower")
    }
    
    @Test("Component initialization costs")
    func componentInitializationCosts() throws {
        let iterations = 100
        
        // Measure fingerprint generation separately
        let fingerprintStart = Date()
        for _ in 0..<iterations {
            _ = Cuid2Generator.createFingerprint()
        }
        let fingerprintDuration = Date().timeIntervalSince(fingerprintStart)
        
        // Measure entropy generation separately  
        let entropyStart = Date()
        for _ in 0..<iterations {
            _ = Cuid2Generator.createEntropy(length: 24)
        }
        let entropyDuration = Date().timeIntervalSince(entropyStart)
        
        // Measure full generator init
        let generatorStart = Date()
        for _ in 0..<iterations {
            _ = Cuid2Generator()
        }
        let generatorDuration = Date().timeIntervalSince(generatorStart)
        
        print("Initialization component costs (\(iterations) iterations):")
        print("  Fingerprint: \(fingerprintDuration * 1000 / Double(iterations))ms avg")
        print("  Entropy: \(entropyDuration * 1000 / Double(iterations))ms avg")
        print("  Full generator: \(generatorDuration * 1000 / Double(iterations))ms avg")
        print("  Overhead: \((generatorDuration - fingerprintDuration - entropyDuration) * 1000 / Double(iterations))ms")
    }
    
    // MARK: - Generator Initialization
    
    @Test("Generator initialization overhead")
    func generatorInitializationPerformance() throws {
        let iterations = 1000
        
        let start = Date()
        for _ in 0..<iterations {
            _ = Cuid2Generator()
        }
        let duration = Date().timeIntervalSince(start)
        
        print("Generator init: \(duration * 1000 / Double(iterations))ms per initialization")
        #expect(duration < 5.0, "1000 generator initializations should complete in under 5 seconds")
    }
    
    @Test("Custom fingerprint initialization")
    func customFingerprintPerformance() throws {
        let iterations = 1000
        
        let start = Date()
        for _ in 0..<iterations {
            _ = Cuid2Generator(fingerprint: "custom_fingerprint_\(iterations)")
        }
        let duration = Date().timeIntervalSince(start)
        
        print("Custom fingerprint init: \(duration * 1000 / Double(iterations))ms per initialization")
    }
    
    // MARK: - Concurrent Generation
    
    @Test("Concurrent ID generation")
    func concurrentGenerationPerformance() async throws {
        let iterationsPerTask = 1000
        let taskCount = 4
        
        let start = Date()
        
        await withTaskGroup(of: Int.self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    let generator = Cuid2Generator()
                    var count = 0
                    for _ in 0..<iterationsPerTask {
                        _ = generator.generate()
                        count += 1
                    }
                    return count
                }
            }
            
            var totalGenerated = 0
            for await count in group {
                totalGenerated += count
            }
            
            let duration = Date().timeIntervalSince(start)
            let throughput = Double(totalGenerated) / duration
            print("Concurrent (\(taskCount) tasks): \(Int(throughput)) IDs/sec")
        }
    }
    
    // MARK: - Component Performance
    
    @Test("SHA3-512 hashing performance")
    func hashingPerformance() throws {
        let testInputs = (0..<100).map { "test_input_\($0)_with_additional_entropy_data" }
        let iterations = 100
        
        let start = Date()
        for _ in 0..<iterations {
            for input in testInputs {
                _ = Cuid2Generator.hash(input: input)
            }
        }
        let duration = Date().timeIntervalSince(start)
        
        let totalHashes = iterations * testInputs.count
        let hashesPerSecond = Double(totalHashes) / duration
        print("Hashing: \(Int(hashesPerSecond)) hashes/sec")
    }
    
    @Test("Entropy generation performance")
    func entropyGenerationPerformance() throws {
        let iterations = 10_000
        
        let start = Date()
        for _ in 0..<iterations {
            _ = Cuid2Generator.createEntropy(length: 32)
        }
        let duration = Date().timeIntervalSince(start)
        
        let entropyPerSecond = Double(iterations) / duration
        print("Entropy: \(Int(entropyPerSecond)) generations/sec")
    }
    
    @Test("Fingerprint generation performance")
    func fingerprintGenerationPerformance() throws {
        let iterations = 1000
        
        let start = Date()
        for _ in 0..<iterations {
            _ = Cuid2Generator.createFingerprint()
        }
        let duration = Date().timeIntervalSince(start)
        
        print("Fingerprint: \(duration * 1000 / Double(iterations))ms per generation")
    }
    
    // MARK: - Validation Performance
    
    @Test("ID validation performance")
    func validationPerformance() throws {
        let generator = Cuid2Generator()
        let ids = generator.generate(times: 1000)
        let iterations = 10
        
        let start = Date()
        for _ in 0..<iterations {
            for id in ids {
                _ = isCuid2(id: id)
            }
        }
        let duration = Date().timeIntervalSince(start)
        
        let validationsPerSecond = Double(iterations * ids.count) / duration
        print("Validation: \(Int(validationsPerSecond)) validations/sec")
    }
    
    // MARK: - Memory Pressure
    
    @Test("Memory usage under load")
    func memoryPressureTest() throws {
        let generator = Cuid2Generator()
        let iterations = 100_000
        
        let start = Date()
        for _ in 0..<iterations {
            _ = generator.generate()
        }
        let duration = Date().timeIntervalSince(start)
        
        print("Generated \(iterations) IDs in \(duration)s without holding references")
        #expect(duration < 30.0, "Should handle 100k generations without excessive memory pressure")
    }
    
    // MARK: - Comprehensive Baseline
    
    @Test("Comprehensive performance baseline")
    func baselineMetrics() throws {
        print("\n=== CUID2 Performance Baseline ===\n")
        
        let generator = Cuid2Generator()
        let iterations = 10_000
        
        // Warm up
        for _ in 0..<100 {
            _ = generator.generate()
        }
        
        // Single ID generation
        let singleStart = Date()
        for _ in 0..<iterations {
            _ = generator.generate()
        }
        let singleDuration = Date().timeIntervalSince(singleStart)
        
        // Batch generation
        let batchStart = Date()
        _ = generator.generate(times: iterations)
        let batchDuration = Date().timeIntervalSince(batchStart)
        
        // Component benchmarks
        let hashStart = Date()
        for _ in 0..<1000 {
            _ = Cuid2Generator.hash(input: "benchmark_test_input")
        }
        let hashDuration = Date().timeIntervalSince(hashStart)
        
        // Calculate metrics
        let singleThroughput = Double(iterations) / singleDuration
        let batchThroughput = Double(iterations) / batchDuration
        let hashThroughput = 1000.0 / hashDuration
        
        print("Single ID Generation:")
        print("  Total time: \(String(format: "%.2f", singleDuration * 1000))ms for \(iterations) IDs")
        print("  Throughput: \(Int(singleThroughput)) IDs/second")
        print("  Latency: \(String(format: "%.2f", singleDuration / Double(iterations) * 1_000_000))μs per ID")
        print("")
        print("Batch Generation:")
        print("  Total time: \(String(format: "%.2f", batchDuration * 1000))ms for \(iterations) IDs")
        print("  Throughput: \(Int(batchThroughput)) IDs/second")
        print("  Latency: \(String(format: "%.2f", batchDuration / Double(iterations) * 1_000_000))μs per ID")
        print("")
        print("Component Performance:")
        print("  SHA3-512 hashing: \(Int(hashThroughput)) hashes/second")
        print("")
        print("Speedup (batch vs single): \(String(format: "%.2f", singleDuration / batchDuration))x")
        print("\n================================\n")
        
        #expect(singleDuration < 2.0, "Single generation should complete in under 2 seconds for 10k IDs")
        #expect(batchDuration < 2.0, "Batch generation should complete in under 2 seconds for 10k IDs")
    }
}