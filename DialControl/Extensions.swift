//
//  Extensions.swift
//  DialControl
//
//  Created by Phil Kirby on 3/9/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

extension PilotStateData {
    private func updateState(label: String,
                     state: Bool,
                     handler: (inout PilotStateData) -> ()
    ) {
        measure(name: "\(label)(state:\(state)") {
            self.change(update: { psd in
                global_os_log(label, state.description)
                handler(&psd)
            })
        }
    }
    
    func updateSystemPhaseState(value: Bool) {
        updateState(label: "FeatureId.firstPlayerUpdate", state: value) {
            $0.updateSystemPhaseAction(value: value)
        }
    }
}

extension Publisher {
    func catchResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        self
            .map(Result.success)
            .catch { Just(Result.failure($0)) }
            .eraseToAnyPublisher()
    }
}

extension View {
    func popup<T: View>(
        isPresented: Bool,
        alignment: Alignment = .center,
        direction: Popup<T>.Direction = .bottom,
        @ViewBuilder content: () -> T
    ) -> some View {
        return modifier(Popup(isPresented: isPresented,
                              alignment: alignment,
                              direction: direction,
                              content: content))
    }
}

extension View {
    func debugType() -> some View {
        print(type(of: self))
        return self
    }
}

extension View {
    func navigate<Content: View>(
        @ViewBuilder to destination: () -> Content
    ) -> some View {
        NavigationLink(destination: destination(), label: { self })
    }
}

/// Creates a new `View` based on a condition.
///
/// `return myView.applyIf(condition: { self.hasWon == true }, apply: { return WinConditionView() })`
///
/// - Parameters:
///   - condition: Closure that is to be evaluated
///   - apply: Closure that returns a new `View`
/// - Returns: a `View`
///
private extension View {
    @ViewBuilder func applyIf<T: View>(_ condition: @autoclosure () -> Bool, apply: (Self) -> T) -> some View {
        if condition() {
            apply(self)
        } else {
            self
        }
    }
}

/// Performs a side-effect.
/// Use `map()` if you want to transform `Output`
///
/// return URLSession.shared.dataTaskPublisher(for: at)
///     .compactMap { UIImage(data: $0.data) }
///     .do { print($0) }
///
/// - Parameters:
///   - handler: Closure that contains the side-effect logic
/// - Returns: The publishers' output (as-is)
///
extension Publisher {
    func `do`(handler: @escaping (Output) -> ()) -> AnyPublisher<Output, Failure> {
        self.handleEvents(receiveOutput: { value in
            handler(value)
        }).eraseToAnyPublisher()
    }
}

/*
    store.statePublisher
        .map { state in buildViewProperties(state) }
        .weakSink(on: self, handler: setViewProperties)
 
    func buildViewProperties(state: CountViewState) -> CountViewProperties { ... }
 
    func setViewProperties(_ properties: CountViewProperties) {
        properties = properties
    }
 */
extension Publisher where Failure == Never {
    func weakSink<T: AnyObject>(on object: T, handler: @escaping (Output) -> ()) -> AnyCancellable
    {
        sink { [weak object] value in
            handler(value)
        }
    }
}

extension Publisher {
    
    /// Converts the output into a `Result<Output, Failure>` type.
    /// This catches any errors and stores them in the `Result`
    /// - Parameters:
    /// - Returns: the publishers' output converted to a `Result<Output, Failure>` object.
    func convertToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        self.map(Result.success)
            .catch { Just(.failure($0)) }
            .eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Never {
    func weakAssign<T: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<T, Output>,
        on object: T
    ) -> AnyCancellable {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher where Self.Output : Equatable {
    public func distinct() -> AnyPublisher<Self.Output, Self.Failure> {
        self.scan(([], nil)) {
            $0.0.contains($1) ? ($0.0, nil) : ($0.0 + [$1], $1)
        }
        .compactMap { $0.1 }
        .eraseToAnyPublisher()
    }
}

public extension Cancellable {
    func onCancel(_ block: @escaping () -> Void) -> AnyCancellable {
        AnyCancellable {
            self.cancel()
            block()
        }
    }
}

public extension View {
    func myAlert(isPresented: Binding<Bool>,
               title: String,
               message: String? = nil,
               dismissButton: Alert.Button? = nil) -> some View
    {

        alert(isPresented: isPresented) {
            Alert(title: Text(title),
                  message: {
                    if let message = message { return Text(message) }
                    else { return nil } }(),
                  dismissButton: dismissButton)
        }
    }
}

extension View {
    func addLongPressAlert(_ isPresented: Binding<Bool>, _ message: String) -> some View {
        self.modifier(LongPressAlertModifier(isPresented: isPresented, message: message))
    }
}

extension View {
    func addAlert(_ showAlert: Binding<Bool>, properties: AlertModifier.Properties) -> some View {
        self.modifier(AlertModifier(showAlert: showAlert,
                                    properties: properties))
    }
}
extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

extension Binding {
    /// Execute block when value is changed.
    ///
    /// Example:
    ///
    ///     Slider(value: $amount.didSet { print($0) }, in: 0...10)
    func didSet(execute: @escaping (Value) -> Void) -> Binding {
        return Binding(
            get: {
                return self.wrappedValue
            },
            set: {
                self.wrappedValue = $0
                execute($0)
            }
        )
    }
}

extension Binding {
    
    /// When the `Binding`'s `wrappedValue` changes, the given closure is executed.
    /// - Parameter closure: Chunk of code to execute whenever the value changes.
    /// - Returns: New `Binding`.
    func onUpdate(_ closure: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(get: {
            self.wrappedValue
        }, set: { newValue in
            self.wrappedValue = newValue
            closure(newValue)
        })
    }
}

extension Just {
    var asFuture: Future<Output, Never> {
        .init { promise in
            promise(.success(self.output))
        }
    }
}

extension EnvironmentValues {
    var theme: Int {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// https://stackoverflow.com/questions/58494193/swiftui-rotationeffect-framing-and-offsetting
private struct SizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize,
                       nextValue: () -> CGSize)
    {
        value = nextValue()
    }
}


extension Array where Element == AngleRange {
    func getSegment(withAngle: CGFloat) -> UInt {
        print("withAngle: \(withAngle)")
        var ret: UInt = 0
        
        for (index, item) in self.enumerated() {
            print("Found \(item) at position \(index)")
            
            // Should pass in the negative threshold angle as an input param
            // FIXME: Figure out the correct angles for segment 0 based on index 0
            if (withAngle >= -22.5) && (withAngle < 360) {
                ret = 0
            }
            
            if (withAngle >= item.start) && (withAngle < item.end) {
                print("Found \(withAngle) at index \(index)")
                
                ret = UInt(index)
                return ret
            }
        }
        
        return ret
    }
}

extension View {
    func captureSize(in binding: Binding<CGSize>) -> some View {
        overlay(GeometryReader { proxy in
            Color.clear.preference(key: SizeKey.self, value: proxy.size)
        })
        .onPreferenceChange(SizeKey.self) { size in
            binding.wrappedValue = size
        }
    }
}

extension View {
    func rotated(_ angle: Angle = .degrees(-45)) -> some View {
        Rotated(self, angle: angle)
    }
}

extension StringProtocol {
    subscript(_ offset: Int) -> Element
    {
        self[index(startIndex, offsetBy: offset)]
    }
    
    subscript(_ range: Range<Int>) -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count)
    }
    
    subscript(_ range: ClosedRange<Int>) -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count)
    }
    
    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence { prefix(range.upperBound.advanced(by: 1))
    }
    
    subscript(_ range: PartialRangeUpTo<Int>) -> SubSequence {
        prefix(range.upperBound)
    }
    
    subscript(_ range: PartialRangeFrom<Int>) -> SubSequence {
        suffix(Swift.max(0, count-range.lowerBound))
    }
}

extension View {
    func xPoint(_ withRadius: CGFloat, _ withAngle: CGFloat) -> CGFloat {
        let point: (CGFloat, CGFloat) = pointOnCircle(withRadius: withRadius, withAngle: withAngle)
        print("x: \(point.0)")
        return point.0
    }

    func yPoint(_ withRadius: CGFloat, _ withAngle: CGFloat) -> CGFloat {
        let point: (CGFloat, CGFloat) = pointOnCircle(withRadius: withRadius, withAngle: withAngle)
        print("y: \(point.1)")
        return point.1
    }
    
    func pointOnCircle(withRadius: CGFloat, withAngle: CGFloat) -> (CGFloat, CGFloat) {
        let angle = CGFloat(withAngle - 90) * .pi / 180
        let x = withRadius * cos(angle)
        let y = withRadius * sin(angle)

//        return CGPoint(x: x, y: y)
        return (x, y)
    }
    
    func pointOnCircle(withRadius: CGFloat, withAngle: CGFloat) -> CGPoint {
        let angle = CGFloat(withAngle - 90) * .pi / 180
        let x = withRadius * cos(angle)
        let y = withRadius * sin(angle)

        return CGPoint(x: x, y: y)
//        return (x, y)
    }
}

func deg2rad(_ number: Double) -> Double {
    return number * .pi / 180
}

extension Shape {
    /// fills and strokes a shape
    public func fill<S:ShapeStyle>(_ fillContent: S,
                                   stroke: StrokeStyle) -> some View
    {
        ZStack {
            self.fill(fillContent)
            self.stroke(style:stroke)
        }
    }
    
    /// fills and strokes a shape
    public func fill<S:ShapeStyle>(_ fillContent: S,
                                   opacity: Double,
                                   strokeWidth: CGFloat,
                                   strokeColor: S) -> some View
    {
        ZStack {
            self.fill(fillContent).opacity(opacity)
            self.stroke(strokeColor, lineWidth: strokeWidth)
        }
    }
}

extension Image {
    
}

extension String {

    func fileName() -> String {
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }

    func fileExtension() -> String {
        return URL(fileURLWithPath: self).pathExtension
    }
}

extension String {
    func removeAll(character: String) -> String {
        return components(separatedBy: character).joined()
    }
}

extension Array where Element: Equatable {
    func indexes(of element: Element) -> [Int] {
        return self.enumerated().filter({ element == $0.element }).map({ $0.offset })
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}


extension SquadData {
    func getPilotState(index: Int) -> PilotState {
        let arr = Array(pilotState as! Set<PilotState>)
        return arr[index]
    }
    
    public var pilotStateArray: [PilotState] {
        guard let pilotState = pilotState as? Set<PilotState> else {
            return []
        }
        
        return Array(pilotState)
    }
}

/// Flips multiple different types of assets
/// Card, Manuever Dial
enum FlipCard {
    case frontToBack    // Display the back
    case backToFront    // Display the front
    
    func execute(asset: inout FlippableAsset) {
        switch(self) {
            case .frontToBack :
                asset.flip()
            case .backToFront :
                asset.flip()
        }
    }
}

protocol FlipManageable : AnyObject {
    var flippableAssets: [FlippableAsset] { get set }
    
    func addAsset(asset: FlippableAsset)
}

extension FlipManageable {
    // Atomic operations
    func addAsset(asset: FlippableAsset) {
        flippableAssets.append(asset)
    }
    
    func setToFront(id: UUID) {
        if var asset = getAsset(by: id) {
            backToFrontCommand.execute(asset: &asset)
        }
    }
    
    func setToBack(id: UUID) {
        if var asset = getAsset(by: id) {
            backToFrontCommand.execute(asset: &asset)
        }
    }
    
    private func getAsset(by id: UUID) -> FlippableAsset? {
        return (flippableAssets.filter{ $0.id == id }.first)
    }
    
    func flip(id: UUID) {
        // Find the asset
        if var asset = getAsset(by: id) {
            if asset.frontSide == true {
                frontToBackCommand.execute(asset: &asset)
            } else {
                backToFrontCommand.execute(asset: &asset)
            }
        }
    }

    // Batch operations
    func flip_all() {
        flippableAssets.mutateEach{ card in
            card.flip()
        }
    }
    
    func setAllTo(isFront: Bool) {
        flippableAssets.mutateEach{ card in
            card.frontSide = isFront
        }
    }
    
    func setToFront() {
        self.setAllTo(isFront: true)
    }
    
    func setToBack() {
        self.setAllTo(isFront: false)
    }
    
    func reveal_all() {
        self.setToFront()
    }
    
    func hideAll() {
        self.setToBack()
    }

    // Commands
    var frontToBackCommand: FlipCard { FlipCard.frontToBack }
    var backToFrontCommand: FlipCard  { FlipCard.backToFront }
}

class UpgradeFlipCardViewModel: FlipManageable {
    var flippableAssets : [FlippableAsset] = []
    var frontSide: Bool = true
    
    func addUpgradeCard() {
        self.addAsset(asset: UpgradeCard(frontSide: true))
    }
    
    func flipCard(id: UUID) {
        flip(id: id)
    }
}

class ShipFlipCardViewModel : FlipManageable {
    var flippableAssets : [FlippableAsset] = []
}

class UpgradeCard : FlippableAsset, Identifiable {
    var id = UUID()
    var frontSide: Bool
    
    init(frontSide: Bool) {
        self.frontSide = frontSide
    }
}

class ManeuverDial : FlippableAsset, Identifiable  {
    var id = UUID()
    var frontSide: Bool
    
    init(frontSide: Bool) {
        self.frontSide = frontSide
    }
}

protocol FlippableAsset {
    var id: UUID { get set }
    var frontSide: Bool { get set }
}

extension FlippableAsset {
    mutating func flip() { frontSide.toggle() }
}

///https://stackoverflow.com/questions/29777891/swift-how-to-mutate-a-struct-object-when-iterating-over-it
extension Array {
    mutating func mutateEach(by transform: (inout Element) throws -> Void) rethrows {
        self = try map { el in
            var el = el
            try transform(&el)
            return el
        }
     }
}

func executionTimeInterval(block: () -> ()) -> CFTimeInterval {
    let start = CACurrentMediaTime()
    block();
    let end = CACurrentMediaTime()
    return end - start
}

func executionTime(_ label: String, block: () -> ()) {
    let start = CFAbsoluteTimeGetCurrent()
    // run your work
    block();
    let diff = CFAbsoluteTimeGetCurrent() - start
    print("\(label) Took \(diff) seconds")
}

extension Array where Element: Publisher {

    
    /// Combines an array of publishers with a shared type and error type.
    /// - Returns: <#description#>
    /// – Jonathan Crooke
    /// https://stackoverflow.com/questions/65397556/swift-combine-how-to-combine-publishers-and-sink-when-only-one-publishers-valu
    func combineAll() -> AnyPublisher<[Element.Output], Element.Failure>? {         guard let first = first else { return nil }
        
        return dropFirst()
            .reduce(into: AnyPublisher(first.map { [$0] })) {
                $0 = $0.combineLatest($1) { $0 + [$1] }                     .eraseToAnyPublisher()
                }
    }
}

public extension Publisher {
    /// Performs a sink operation
    ///
    /// - note: Reduces boilerplate code
    ///
    /// - returns: A cancellable
    func compactSink(id: String) -> AnyCancellable {
        let logValue : (Self.Output) -> Void = { value in
            global_os_log(id, "value: \(value)")
        }
        
        return self.sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    // no associated data, but you can react to knowing the
                    // request has been completed
                    global_os_log(id, "completion: .finished")
                    break
                case .failure(let anError):
                    // do what you want with the error details, presenting,
                    // logging, or hiding as appropriate
                    global_os_log(id, "completion: .failure(\(anError))")
                    break
                }
        }, receiveValue: logValue)
    }
}



