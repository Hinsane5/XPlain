import XCTest

@testable import XPlain

/// M6.1: the typed settings store round-trips every value through an injected
/// `UserDefaults`, and returns the documented default when a key is unset.
final class SettingsStoreTests: XCTestCase {
  private var suiteName: String!
  private var defaults: UserDefaults!
  private var store: SettingsStore!

  override func setUp() {
    super.setUp()
    suiteName = "XPlainTests-\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)
    store = SettingsStore(defaults: defaults)
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
    defaults = nil
    store = nil
    super.tearDown()
  }

  func testDefaultsWhenNothingIsStored() {
    XCTAssertEqual(store.liveZoomFollowMode, .cursorCentered)
    XCTAssertEqual(store.recordingScope, .fullDisplay)
    XCTAssertFalse(store.capturesSystemAudio)
    XCTAssertFalse(store.capturesMicrophone)
    XCTAssertEqual(store.initialZoomLevel, ZoomRenderer.defaultScale)
    XCTAssertEqual(store.zoomStep, ZoomRenderer.defaultStep)
    XCTAssertTrue(store.animateZoomIn)  // default true, not the bool-zero default
    XCTAssertEqual(store.defaultPenColor, .red)
    XCTAssertEqual(store.defaultPenWidth, 3)
    XCTAssertEqual(store.textFontSize, AnnotationCanvas.defaultTextSize)
    XCTAssertEqual(store.activeDisplayTarget, .underCursor)
    XCTAssertEqual(store.recordingFolder, Recorder.defaultSaveDirectory)
    XCTAssertEqual(store.highlighterOpacity, 0.4)
    XCTAssertEqual(store.recordingQuality, .high)
    XCTAssertFalse(store.hasCompletedOnboarding)
  }

  func testOnboardingFlagRoundTrips() {
    XCTAssertFalse(store.hasCompletedOnboarding)
    store.hasCompletedOnboarding = true
    XCTAssertTrue(store.hasCompletedOnboarding)
  }

  func testNewPaneSettingsRoundTrip() {
    store.highlighterOpacity = 0.7
    store.recordingQuality = .low
    XCTAssertEqual(store.highlighterOpacity, 0.7)
    XCTAssertEqual(store.recordingQuality, .low)
  }

  func testEnumRoundTrips() {
    store.liveZoomFollowMode = .edgePush
    store.recordingScope = .selectedRegion
    store.defaultPenColor = .green
    store.activeDisplayTarget = .mainDisplay
    XCTAssertEqual(store.liveZoomFollowMode, .edgePush)
    XCTAssertEqual(store.recordingScope, .selectedRegion)
    XCTAssertEqual(store.defaultPenColor, .green)
    XCTAssertEqual(store.activeDisplayTarget, .mainDisplay)
  }

  func testBoolRoundTrips() {
    store.capturesSystemAudio = true
    store.capturesMicrophone = true
    store.animateZoomIn = false  // flip the default-true one
    XCTAssertTrue(store.capturesSystemAudio)
    XCTAssertTrue(store.capturesMicrophone)
    XCTAssertFalse(store.animateZoomIn)
  }

  func testNumericRoundTrips() {
    store.initialZoomLevel = 4.5
    store.zoomStep = 0.5
    store.defaultPenWidth = 12
    store.textFontSize = 48
    XCTAssertEqual(store.initialZoomLevel, 4.5)
    XCTAssertEqual(store.zoomStep, 0.5)
    XCTAssertEqual(store.defaultPenWidth, 12)
    XCTAssertEqual(store.textFontSize, 48)
  }

  func testURLRoundTrips() {
    let folder = URL(fileURLWithPath: "/tmp/xplain-custom")
    store.recordingFolder = folder
    XCTAssertEqual(store.recordingFolder, folder)
  }

  func testValuesPersistToTheBackingDefaults() {
    // A second store over the same defaults sees the first store's writes —
    // proving it's really persisting, not just holding in-memory.
    store.recordingScope = .selectedRegion
    store.initialZoomLevel = 6
    let reopened = SettingsStore(defaults: defaults)
    XCTAssertEqual(reopened.recordingScope, .selectedRegion)
    XCTAssertEqual(reopened.initialZoomLevel, 6)
  }
}
