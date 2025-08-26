import Foundation

import BigInt
import CryptoSwift
import CryptoKit

// Configuration enum for choosing implementation
public enum Cuid2Config {
    case fast
    case secure
}

// Letters from a to z in ASCII
let alphabet = (97 ..< 123).map { String(UnicodeScalar(UInt8($0))) }
var randomLetter: String { alphabet.randomElement()! }

// Fast base36 encoding support
private let base36Chars: [Character] = Array("0123456789abcdefghijklmnopqrstuvwxyz")

public final class Cuid2SessionCounter {
    private var value: Int
    private var fastValue: UInt64?
    private let lock = NSLock()
    private let config: Cuid2Config

    private static let initialCountMax = 476_782_367

    public init(initial count: Int? = nil, config: Cuid2Config = .fast) {
        self.config = config
        value = count ?? Cuid2SessionCounter.randomCount
        if config == .fast {
            fastValue = UInt64(value)
        }
    }

    public func next() -> Int {
        if config == .fast {
            lock.lock()
            defer { lock.unlock() }
            fastValue! &+= 1
            return Int(fastValue! % UInt64(Cuid2SessionCounter.initialCountMax))
        }
        value += 1
        return value
    }

    public static var randomCount: Int { Int.random(in: 0 ..< initialCountMax) }
}

public struct Cuid2Generator {
    private let counter: Cuid2SessionCounter
    private let salt: String
    private let fingerprint: String
    private let config: Cuid2Config
    private let fastSalt: [UInt8]?

    public let length: Int

    public static let defaultLength = 24
    public static let minLength = 2
    public static let maxLength = 98
    public static let bigLength = 32

    public init(counter: Cuid2SessionCounter? = nil, length: Int? = nil, fingerprint: String? = nil, config: Cuid2Config = .fast) {
        self.config = config
        self.length = min(max(length ?? Cuid2Generator.defaultLength, Cuid2Generator.minLength), Cuid2Generator.maxLength)
        self.counter = counter ?? Cuid2SessionCounter(config: config)
        
        if config == .fast {
            self.fastSalt = (0..<32).map { _ in UInt8.random(in: 0..<36) }
            self.salt = ""
            self.fingerprint = fingerprint ?? Cuid2Generator.createFingerprintFast()
        } else {
            self.fastSalt = nil
            self.salt = Cuid2Generator.createEntropy(length: self.length)
            self.fingerprint = fingerprint ?? Cuid2Generator.createFingerprint()
        }
    }

    public func generate() -> String {
        if config == .fast {
            return generateFast()
        }
        
        let time = String(Int64(Date.now.timeIntervalSince1970) * 1000, radix: 36)
        let input = time + salt + String(counter.next(), radix: 36) + fingerprint
        let hashed = Cuid2Generator.hash(input: input)
        return "\(randomLetter)\(hashed.dropFirst().prefix(length - 1))"
    }
    
    private func generateFast() -> String {
        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        let count = UInt64(counter.next())
        
        var inputData = Data(capacity: 128)
        withUnsafeBytes(of: timestamp) { inputData.append(contentsOf: $0) }
        inputData.append(contentsOf: fastSalt!)
        withUnsafeBytes(of: count) { inputData.append(contentsOf: $0) }
        inputData.append(contentsOf: fingerprint.utf8.prefix(32))
        
        let hash = SHA256.hash(data: inputData)
        let encoded = fastBase36EncodeHash(hash)
        let firstChar = base36Chars[Int.random(in: 10..<36)]
        
        return String(firstChar) + encoded.prefix(length - 1)
    }
    
    private func fastBase36EncodeHash(_ hash: SHA256.Digest) -> String {
        var result = ""
        result.reserveCapacity(64)
        
        var carry: UInt16 = 0
        for byte in hash {
            let value = UInt16(byte) + carry * 256
            let digit = value % 36
            carry = value / 36
            result.append(base36Chars[Int(digit)])
            
            if carry > 0 && result.count < 64 {
                result.append(base36Chars[Int(carry % 36)])
                carry = carry / 36
            }
        }
        
        while carry > 0 && result.count < 64 {
            result.append(base36Chars[Int(carry % 36)])
            carry = carry / 36
        }
        
        return result
    }

    public func generate(times: Int) -> [String] {
        let times = max(times, 1)
        return Array(repeating: "", count: times).map { _ in generate() }
    }

    static func hash(input: String) -> String {
        let hasher = SHA3(variant: .sha512)
        let data = Data(hasher.calculate(for: Array(input.utf8)))
        let value = BigInt(data)

        return String(String(value, radix: 36).dropFirst())
    }

    static func createEntropy(length times: Int = bigLength) -> String {
        let times = max(times, 1)

        var entropy = ""

        for _ in 0 ..< times {
            entropy += String(UInt8.random(in: 0 ..< 36), radix: 36)
        }

        return entropy
    }

    static func createFingerprintFast() -> String {
        struct Cache {
            static var value: String?
            static let lock = NSLock()
        }
        
        Cache.lock.lock()
        defer { Cache.lock.unlock() }
        
        if let cached = Cache.value {
            return cached
        }
        
        let pid = ProcessInfo.processInfo.processIdentifier
        let machTime = mach_absolute_time()
        let random = UInt64.random(in: 0..<UInt64.max)
        
        var data = Data()
        withUnsafeBytes(of: pid) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: machTime) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: random) { data.append(contentsOf: $0) }
        
        for (idx, (key, _)) in ProcessInfo.processInfo.environment.enumerated() where idx < 5 {
            data.append(contentsOf: key.utf8.prefix(20))
        }
        
        let hash = SHA256.hash(data: data)
        let fingerprint = fastBase36Encode(hash.prefix(16))
        Cache.value = fingerprint
        return fingerprint
    }
    
    private static func fastBase36Encode<T: Sequence>(_ bytes: T) -> String where T.Element == UInt8 {
        var result = ""
        result.reserveCapacity(32)
        
        for byte in bytes {
            let high = Int(byte) / 36
            let low = Int(byte) % 36
            result.append(base36Chars[high % 36])
            result.append(base36Chars[low])
        }
        
        return result
    }
    
    static func createFingerprint(from data: String? = nil) -> String {
        let hashed: String

        let entropy = createEntropy(length: Cuid2Generator.bigLength)

        if let data {
            hashed = hash(input: data + entropy)
        } else {
            // Avoid ProcessInfo.processInfo.hostName - it can take 12ms+ on macOS
            // Use a combination of faster sources for uniqueness
            let id = String(ProcessInfo.processInfo.processIdentifier)
            
            // Use mach_absolute_time for additional entropy instead of hostname
            var info = mach_timebase_info()
            mach_timebase_info(&info)
            let machTime = String(mach_absolute_time())
            
            // Use a subset of env keys to reduce string operations
            let envKeys = ProcessInfo.processInfo.environment.keys
                .prefix(10)  // Limit to first 10 keys for performance
                .joined()
            
            let data = id + machTime + envKeys

            hashed = hash(input: data + entropy)
        }

        return String(hashed.prefix(Cuid2Generator.bigLength))
    }
}

public func createId(counter: Cuid2SessionCounter? = nil, length: Int? = nil, fingerprint: String? = nil, config: Cuid2Config = .fast) -> String {
    Cuid2Generator(counter: counter, length: length, fingerprint: fingerprint, config: config).generate()
}

public func isCuid2(id: String, minLength: Int = Cuid2Generator.minLength, maxLength: Int = Cuid2Generator.maxLength) -> Bool {
    let minLength = max(minLength, Cuid2Generator.minLength)
    let maxLength = min(maxLength, Cuid2Generator.maxLength)

    let length = id.count

    guard length >= minLength, length <= maxLength else { return false }
    guard id.utf8.allSatisfy({ ($0 > 47 && $0 < 58) || ($0 > 64 && $0 < 91) || ($0 > 96 && $0 < 123) }) else { return false }

    return true
}
