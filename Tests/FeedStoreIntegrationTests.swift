//
//  FeedStoreIntegrationTests.swift
//  Tests
//
//  Created by Caio Zullo on 01/09/2020.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge

class FeedStoreIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
     
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliversNoEmptyOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieve: .empty)
    }

    func test_retrieve_deliversFeedInsertedOnAnotherInstance() {
        let storeToInsert = makeSUT()
        let storeToLoad = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()

        insert((feed, timestamp), to: storeToInsert)

        expect(storeToLoad, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_insert_overridesFeedInsertedOnAnotherInstance() {
        let storeToInsert = makeSUT()
        let storeToOverride = makeSUT()
        let storeToLoad = makeSUT()

        insert((uniqueImageFeed(), Date()), to: storeToInsert)

        let latestFeed = uniqueImageFeed()
        let latestTimestamp = Date()
        insert((latestFeed, latestTimestamp), to: storeToOverride)

        expect(storeToLoad, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_delete_deletesFeedInsertedOnAnotherInstance() {
//        let storeToInsert = makeSUT()
//        let storeToDelete = makeSUT()
//        let storeToLoad = makeSUT()
//
//        insert((uniqueImageFeed(), Date()), to: storeToInsert)
//
//        deleteCache(from: storeToDelete)
//
//        expect(storeToLoad, toRetrieve: .empty)
    }
    
    // - MARK: Helpers
    
    private func makeSUT() -> FeedStore {
        let bundle = Bundle(for: CoreDataFeedStore.self)
        let store = try! CoreDataFeedStore(storeURL: storeURL(), bundle: bundle)
        trackForMemoryLeak(store)
        return store
    }
    
    private func setupEmptyStoreState() {
        clearCache()
    }

    private func undoStoreSideEffects() {
        clearCache()
    }
    
    private func clearCache(file: StaticString = #file, line: UInt = #line) {
        try? FileManager.default.removeItem(at: storeURL())
    }
    
    private func storeURL() -> URL {
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesURL.appendingPathComponent("Model.store")
    }
}
