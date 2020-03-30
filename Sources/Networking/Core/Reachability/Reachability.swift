#if !os(watchOS)

import Foundation

// MARK: - Reachability

/// Defines the various states of network reachability.
///
/// - unknown: It is unknown whether the network is reachable.
/// - notReachable: The network is not reachable.
/// - reachable: The network is reachable. Associated value indicates the connection type.
public enum ReachabilityStatus: Equatable {
    case unknown
    case notReachable
    case reachable(ConnectionType)

    /// Whether the network is reachable, regardless of the connection type.
    public var isReachable: Bool {
        switch self {
        case .reachable: return true
        default: return false
        }
    }

    // MARK: Connectivity

    /// Defines the various states of networking connection types.
    ///
    /// - ethernetOrWiFi: The connection type is either over Ethernet or WiFi.
    /// - cellular: The connection type is a cellular connection.
    public enum ConnectionType {
        case ethernetOrWiFi
        case cellular
    }

    // MARK: Equatable

    /// Returns whether the two network reachability status values are equal.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side value to compare.
    ///   - rhs: The right-hand side value to compare.
    /// - Returns: `true` if both states are equal, `false` otherwise.
    static public func == (lhs: ReachabilityStatus, rhs: ReachabilityStatus) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true
        case (.notReachable, .notReachable):
            return true
        case let (.reachable(lhsConnectionType), .reachable(rhsConnectionType)):
            return lhsConnectionType == rhsConnectionType
        default:
            return false
        }
    }
}

// MARK: - Manager

/// Defines the protocol to be implemented by provider specific reachability manager.
public protocol ReachabilityManager {

    /// A closure executed when the network reachability status changes. Takes a single argument: The network reachability status.
    typealias Listener = (ReachabilityStatus) -> Void

    /// The current reachability status for defined host or generic reachability, if host not specified.
    var status: ReachabilityStatus { get }

    /// A closure executed when the network reachability status of `self` changes.
    var listener: Listener? { get set }
}

#endif
