@testable import cuid2
import Testing
import Foundation

@Suite("Performance Benchmarks")
struct PerformanceTests {
    
    @Test("Single ID generation performance")
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
        
        #expect(batchIds.count == iterations)
        #expect(singleIds.count == iterations)
    }
    
    @Test("Concurrent ID generation safety")
    func concurrentGenerationSafety() async throws {
        let iterationsPerTask = 1000
        let taskCount = 4
        
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
            
            print("Concurrent generation: \(taskCount) tasks, \(iterationsPerTask) IDs each, total: \(totalGenerated)")
        }
    }
    
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
}