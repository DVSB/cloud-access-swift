//
//  CloudProviderMockTests.swift
//  CloudAccessTests
//
//  Created by Sebastian Stenzel on 05.05.20.
//  Copyright © 2020 Skymatic GmbH. All rights reserved.
//

import Promises
import XCTest
@testable import CloudAccess

class CloudProviderMockTests: XCTestCase {
	var tmpDirURL: URL!

	override func setUpWithError() throws {
		tmpDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString, isDirectory: true)
		try FileManager.default.createDirectory(at: tmpDirURL, withIntermediateDirectories: true)
	}

	override func tearDownWithError() throws {
		try FileManager.default.removeItem(at: tmpDirURL)
	}

	func testVaultRootContainsFiles() {
		let expectation = XCTestExpectation(description: "vaultRootContainsFiles")
		let provider = CloudProviderMock()
		let url = URL(fileURLWithPath: "pathToVault/d/00/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", isDirectory: true)
		provider.fetchItemList(forFolderAt: url, withPageToken: nil).then { cloudItemList in
			XCTAssertEqual(6, cloudItemList.items.count)
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "dir1.c9r" }))
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "kUDsIDxDMxx1lK0CD1ZftCF376Y=.c9s" }))
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "file1.c9r" }))
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "file2.c9r" }))
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "9j5eVKQZdTojV6zlbxhcCLD_8bs=.c9s" }))
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "aw1qoKFUVs_FnB_n3lGtqKpyIeA=.c9s" }))
		}.catch { error in
			XCTFail("Error in promise: \(error)")
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}

	func testDir1FileContainsDirId() {
		let expectation = XCTestExpectation(description: "dir1FileContainsDirId")
		let provider = CloudProviderMock()
		let remoteURL = URL(fileURLWithPath: "pathToVault/d/00/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/dir1.c9r/dir.c9r", isDirectory: false)
		let localURL = tmpDirURL.appendingPathComponent(UUID().uuidString, isDirectory: false)
		provider.fetchItemMetadata(at: remoteURL).then { metadata -> Promise<Void> in
			XCTAssertEqual(.file, metadata.itemType)
			return provider.downloadFile(from: metadata.remoteURL, to: localURL)
		}.then {
			let downloadedContents = try Data(contentsOf: localURL)
			XCTAssertEqual("dir1-id".data(using: .utf8), downloadedContents)
		}.catch { error in
			XCTFail("Error in promise: \(error)")
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}
}
