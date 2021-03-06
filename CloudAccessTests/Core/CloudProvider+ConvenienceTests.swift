//
//  CloudProvider+ConvenienceTests.swift
//  CloudAccessTests
//
//  Created by Sebastian Stenzel on 26.05.20.
//  Copyright © 2020 Skymatic GmbH. All rights reserved.
//

import Promises
import XCTest
@testable import CloudAccess

class CloudProvider_ConvenienceTests: XCTestCase {
	func testFetchItemListExhaustively() {
		let expectation = XCTestExpectation(description: "fetchItemListExhaustively")
		let provider = ConvenienceCloudProviderMock()
		provider.fetchItemListExhaustively(forFolderAt: URL(fileURLWithPath: "/", isDirectory: true)).then { cloudItemList in
			XCTAssertEqual(6, cloudItemList.items.count)
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "a" }))
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "b" }))
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "c" }))
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "d" }))
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "e" }))
			XCTAssertTrue(cloudItemList.items.contains(where: { $0.name == "f" }))
		}.catch { error in
			XCTFail("Error in promise: \(error)")
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}

	func testDeleteItemIfExistsFulfillsForMissingItem() {
		let expectation = XCTestExpectation(description: "deleteItemIfExists fulfills if the item does not exist in the cloud")
		let nonExistentItemURL = URL(fileURLWithPath: "/nonExistentFolder/", isDirectory: true)
		let provider = ConvenienceCloudProviderMock()
		provider.deleteItemIfExists(at: nonExistentItemURL).catch { error in
			XCTFail("Error in promise: \(error)")
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}

	func testDeleteItemIfExistsFulfillsForExistingItem() {
		let expectation = XCTestExpectation(description: "deleteItemIfExists fulfills if the item does exist in the cloud")
		let existingItemURL = URL(fileURLWithPath: "/thisFolderExistsInTheCloud/", isDirectory: true)
		let provider = ConvenienceCloudProviderMock()
		provider.deleteItemIfExists(at: existingItemURL).catch { error in
			XCTFail("Error in promise: \(error)")
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}

	func testDeleteItemIfExistsRejectsWithErrorOtherThanItemNotFound() {
		let expectation = XCTestExpectation(description: "deleteItemIfExists rejects if deleteItem rejects with an error other than CloudProviderError.itemNotFound")
		let itemURL = URL(fileURLWithPath: "/AAAAA/BBBB/", isDirectory: true)
		let provider = ConvenienceCloudProviderMock()
		provider.deleteItemIfExists(at: itemURL).then {
			XCTFail("Promise fulfilled although we expect an CloudProviderError.noInternetConnection")
		}.catch { error in
			guard case CloudProviderError.noInternetConnection = error else {
				XCTFail("Received unexpected error: \(error)")
				return
			}
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}

	func testCheckForItemExistenceFulfillsForExistingItem() {
		let expectation = XCTestExpectation(description: "checkForItemExistence fulfills with true if the item exists")
		let provider = ConvenienceCloudProviderMock()
		let existingItemURL = URL(fileURLWithPath: "/thisFolderExistsInTheCloud/", isDirectory: true)
		provider.checkForItemExistence(at: existingItemURL).then { itemExists in
			XCTAssertTrue(itemExists)
		}.catch { error in
			XCTFail("Error in promise: \(error)")
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}

	func testCheckForItemExistenceFulfillsForMissingItem() {
		let expectation = XCTestExpectation(description: "checkForItemExistence fulfills with false if the item does not exist")
		let provider = ConvenienceCloudProviderMock()
		let nonExistentItemURL = URL(fileURLWithPath: "/nonExistentFile", isDirectory: false)
		provider.checkForItemExistence(at: nonExistentItemURL).then { itemExists in
			XCTAssertFalse(itemExists)
		}.catch { error in
			XCTFail("Error in promise: \(error)")
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}

	func testCheckForItemExistenceRejectsWithErrorOtherThanItemNotFound() {
		let expectation = XCTestExpectation(description: "checkForItemExistence rejects if fetchItemMetadata rejects with an error other than CloudProviderError.itemNotFound")
		let provider = ConvenienceCloudProviderMock()
		let itemURL = URL(fileURLWithPath: "/AAAAA/BBBB/", isDirectory: true)
		provider.checkForItemExistence(at: itemURL).then { _ in
			XCTFail("Promise fulfilled although we expect an CloudProviderError.noInternetConnection")
		}.catch { error in
			guard case CloudProviderError.noInternetConnection = error else {
				XCTFail("Received unexpected error: \(error)")
				return
			}
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}
}

private class ConvenienceCloudProviderMock: CloudProvider {
	let pages = [
		"0": [
			CloudItemMetadata(name: "a", remoteURL: URL(fileURLWithPath: "/a", isDirectory: false), itemType: .file, lastModifiedDate: nil, size: nil),
			CloudItemMetadata(name: "b", remoteURL: URL(fileURLWithPath: "/b", isDirectory: false), itemType: .file, lastModifiedDate: nil, size: nil)
		],
		"1": [
			CloudItemMetadata(name: "c", remoteURL: URL(fileURLWithPath: "/c", isDirectory: false), itemType: .file, lastModifiedDate: nil, size: nil)
		],
		"2": [
			CloudItemMetadata(name: "d", remoteURL: URL(fileURLWithPath: "/d", isDirectory: false), itemType: .file, lastModifiedDate: nil, size: nil),
			CloudItemMetadata(name: "e", remoteURL: URL(fileURLWithPath: "/e", isDirectory: false), itemType: .file, lastModifiedDate: nil, size: nil),
			CloudItemMetadata(name: "f", remoteURL: URL(fileURLWithPath: "/f", isDirectory: false), itemType: .file, lastModifiedDate: nil, size: nil)
		]
	]

	func fetchItemMetadata(at remoteURL: URL) -> Promise<CloudItemMetadata> {
		let nonExistentItemURL = URL(fileURLWithPath: "/nonExistentFile", isDirectory: false)
		let existingItemURL = URL(fileURLWithPath: "/thisFolderExistsInTheCloud/", isDirectory: true)
		switch remoteURL {
		case nonExistentItemURL:
			return Promise(CloudProviderError.itemNotFound)
		case existingItemURL:
			return Promise(CloudItemMetadata(name: "thisFolderExistsInTheCloud", remoteURL: existingItemURL, itemType: .folder, lastModifiedDate: nil, size: nil))
		default:
			return Promise(CloudProviderError.noInternetConnection)
		}
	}

	func fetchItemList(forFolderAt remoteURL: URL, withPageToken pageToken: String?) -> Promise<CloudItemList> {
		switch pageToken {
		case nil:
			return Promise(CloudItemList(items: pages["0"]!, nextPageToken: "1"))
		case "1":
			return Promise(CloudItemList(items: pages["1"]!, nextPageToken: "2"))
		case "2":
			return Promise(CloudItemList(items: pages["2"]!, nextPageToken: nil))
		default:
			return Promise(CloudProviderError.noInternetConnection)
		}
	}

	func downloadFile(from remoteURL: URL, to localURL: URL) -> Promise<Void> {
		return Promise(CloudProviderError.noInternetConnection)
	}

	func uploadFile(from localURL: URL, to remoteURL: URL, replaceExisting: Bool) -> Promise<CloudItemMetadata> {
		return Promise(CloudProviderError.noInternetConnection)
	}

	func createFolder(at remoteURL: URL) -> Promise<Void> {
		return Promise(CloudProviderError.noInternetConnection)
	}

	func deleteItem(at remoteURL: URL) -> Promise<Void> {
		let nonExistentItemURL = URL(fileURLWithPath: "/nonExistentFolder/", isDirectory: true)
		let existingItemURL = URL(fileURLWithPath: "/thisFolderExistsInTheCloud/", isDirectory: true)
		switch remoteURL {
		case nonExistentItemURL:
			return Promise(CloudProviderError.itemNotFound)
		case existingItemURL:
			return Promise(())
		default:
			return Promise(CloudProviderError.noInternetConnection)
		}
	}

	func moveItem(from oldRemoteURL: URL, to newRemoteURL: URL) -> Promise<Void> {
		return Promise(CloudProviderError.noInternetConnection)
	}
}
