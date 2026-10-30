//
//  Statistics.swift
//  CarLog
//

import Foundation

protocol ExpressibleAsDouble {
    var double: Double { get }
}

extension Double: ExpressibleAsDouble {
    var double: Double { self }
}

extension Float: ExpressibleAsDouble {
    var double: Double { Double(self) }
}

extension Int: ExpressibleAsDouble {
    var double: Double { Double(self) }
}

enum eStat {
    case mean
    case sum
    case cumulative(Double)
    static var Q1: eStat {.cumulative(0.25)}
    static var med: eStat {.cumulative(0.5)}
    static var Q3: eStat {.cumulative(0.75)}
    
    func compute<N: ExpressibleAsDouble & Comparable>(on data: [N]) -> Double {
        switch self {
        case .mean:
            if data.count > 0 {
                return Double(Self.sum.compute(on: data)) / Double(data.count)
            }
            return 0
        case .sum:
            return data.reduce(0.0, {$0 + $1.double})
        case .cumulative(let percentage):
            let ordered = data.sorted(by: {$0 < $1})
            let count = data.count
            
            guard count > 0 else { return 0 }
            let index = min(max(Int((Double(count) * percentage).rounded(.down)), 0), count - 1)

            return Double(ordered[index].double)
        }
    }
}

extension Collection where Element: ExpressibleAsDouble & Comparable {
    
    func statistics(using function: eStat) -> Double {
        function.compute(on: self.map{$0})
    }
    
}
