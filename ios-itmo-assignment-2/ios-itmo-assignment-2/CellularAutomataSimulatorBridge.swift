import Foundation
import CoreGraphics
import CellularAutomataSimulator

private typealias HashedSimulator = Hashed2DCellularAutomata<BinaryCell>
private typealias HashedState = HashedSimulator.State
private typealias SimpleSimulator = Simple2DCellularAutomaton<BinaryCell>
private typealias SimpleState = SimpleSimulator.State

@objc(CASGOLSimulator)
public class GOLSimulator: NSObject {
    private let simulator = HashedSimulator.gameOfLife

    @objc(simulateState:forNumberOfGenerationsAhead:error:)
    public func simulate(state: GOLState, for generations: UInt) throws {
        state.hashedState = try self.simulator.simulate(state.hashedState, generations: generations)
    }
}

@objc(CASGOLState)
public final class GOLState: NSObject, NSCopying {
    private enum Representation {
        case hashed(HashedState)
        case simple(SimpleState)
    }

    private var representation: Representation {
        didSet {
            self.revision += 1
        }
    }

    fileprivate var hashedState: HashedState {
        get {
            switch self.representation {
            case .hashed(let state):
                return state
            case .simple(let state):
                var hashed = HashedState()
                hashed[state.viewport] = state
                return hashed
            }
        }
        set {
            self.representation = .hashed(newValue)
        }
    }

    fileprivate var simpleState: SimpleState {
        get {
            switch self.representation {
            case .hashed(let state):
                return state[state.viewport]
            case .simple(let state):
                return state
            }
        }
        set {
            self.representation = .simple(newValue)
        }
    }

    public override init() {
        self.representation = .simple(.init())
    }

    private init(representation: Representation) {
        self.representation = representation
    }

    fileprivate init(state: HashedState) {
        self.representation = .hashed(state)
    }

    fileprivate init(state: SimpleState) {
        self.representation = .simple(state)
    }

    @objc public var revision: UInt = 0

    @objc public var viewport: CGRect {
        get {
            switch self.representation {
            case .hashed(let state):
                return state.viewport.cgRect
            case .simple(let state):
                return state.viewport.cgRect
            }
        }
        set {
            switch self.representation {
            case .hashed(var state):
                state.viewport = .init(cgRect: newValue)
                self.hashedState = state
            case .simple(var state):
                state.viewport = .init(cgRect: newValue)
                self.simpleState = state
            }
        }
    }

    @objc(substateInRect:)
    public func substate(in rect: CGRect) -> GOLState {
        switch self.representation {
        case .hashed(let state):
            return GOLState(state: state[.init(cgRect: rect)])
        case .simple(let state):
            return GOLState(state: state[.init(cgRect: rect)])
        }
    }

    @objc(setSubstate:inRect:)
    public func setSubstate(_ newValue: GOLState, in rect: CGRect) {
        switch self.representation {
        case .hashed(var state):
            state[.init(cgRect: rect)] = newValue.simpleState
            self.hashedState = state
        case .simple(var state):
            state[.init(cgRect: rect)] = newValue.simpleState
            self.simpleState = state
        }
    }

    @objc(cellAtPoint:)
    public func cell(at point: CGPoint) -> Bool {
        switch self.representation {
        case .hashed(let state):
            return state[.init(cgPoint: point)] == .active
        case .simple(let state):
            return state[.init(cgPoint: point)] == .active
        }
    }

    @objc(setCell:atPoint:)
    public func setCell(_ newValue: Bool, at point: CGPoint) {
        switch self.representation {
        case .hashed(var state):
            state[.init(cgPoint: point)] = newValue ? .active : .inactive
            self.hashedState = state
        case .simple(var state):
            state[.init(cgPoint: point)] = newValue ? .active : .inactive
            self.simpleState = state
        }
    }

    @objc(translateToPoint:)
    public func translate(to point: CGPoint) {
        switch self.representation {
        case .hashed(var state):
            state.translate(to: .init(cgPoint: point))
            self.hashedState = state
        case .simple(var state):
            state.translate(to: .init(cgPoint: point))
            self.simpleState = state
        }
    }

    @objc public func copy(with zone: NSZone? = nil) -> Any {
        GOLState(representation: self.representation)
    }
}

extension Size {
    var cgSize: CGSize {
        CGSize(width: self.width, height: self.height)
    }

    init(cgSize: CGSize) {
        self.init(width: Int(cgSize.width), height: Int(cgSize.height))
    }
}

extension Point {
    var cgPoint: CGPoint {
        CGPoint(x: self.x, y: self.y)
    }

    init(cgPoint: CGPoint) {
        self.init(x: Int(cgPoint.x), y: Int(cgPoint.y))
    }
}

extension Rect {
    var cgRect: CGRect {
        CGRect(origin: self.origin.cgPoint, size: self.size.cgSize)
    }

    init(cgRect: CGRect) {
        self.init(origin: Point(cgPoint: cgRect.origin), size: Size(cgSize: cgRect.size))
    }
}
