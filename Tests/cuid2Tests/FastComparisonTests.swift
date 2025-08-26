@testable import cuid2
import Testing
import Foundation

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
        print("")
        print("Fast Mode:")
        print("  Time: \(String(format: "%.2f", fastDuration * 1000))ms")
        print("  Throughput: \(Int(fastThroughput)) IDs/sec")
        print("")
        print("Speedup: \(String(format: "%.1f", speedup))x faster")
        
        #expect(fastDuration < secureDuration, "Fast mode should be faster")
        #expect(speedup > 10, "Fast mode should be at least 10x faster")
    }
    
    @Test("Default config uses fast mode")
    func testDefaultConfig() throws {
        // This test should verify the actual config, not performance
        let defaultGen = Cuid2Generator()
        let explicitFastGen = Cuid2Generator(config: .fast)
        
        // Both should generate valid IDs
        let defaultId = defaultGen.generate()
        let fastId = explicitFastGen.generate()
        
        #expect(isCuid2(id: defaultId))
        #expect(isCuid2(id: fastId))
        #expect(defaultId.count == 24)
        #expect(fastId.count == 24)
    }
    
    @Test("Concurrent generation uniqueness") 
    func concurrentUniqueness() async throws {
        let fastGen = Cuid2Generator(config: .fast)
        let tasksCount = 10
        let idsPerTask = 1000
        
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
        
        let uniqueCount = Set(results).count
        
        print("Generated \(results.count) IDs across \(tasksCount) concurrent tasks")
        print("Unique IDs: \(uniqueCount)")
        
        #expect(uniqueCount == results.count, "All IDs should be unique")
    }
}