//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import CoreData

extension ManagedCache {
    var managedFeedImages: [ManagedFeedImage] {
        return feed?.array as? [ManagedFeedImage] ?? []
    }
    
    static func UniqueCache(in context: NSManagedObjectContext) throws -> ManagedCache {
        try context.fetch(ManagedCache.fetchRequest() as NSFetchRequest<ManagedCache>).forEach({ (cache) in
            context.delete(cache)
        })
        
        return ManagedCache(context: context)
    }
}

extension ManagedFeedImage {
    var localFeedImage: LocalFeedImage {
        return LocalFeedImage(id: id!, description: descriptions, location: location, url: url!)
    }
}

class CoreDataFeedStore: FeedStore {
    private lazy var context: NSManagedObjectContext = container.newBackgroundContext()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        guard let modelURL = Bundle(for: FeedStoreChallengeTests.self).url(forResource: "Model", withExtension: "momd") else {
            fatalError("Could not find Model.xcdatamodeld")
        }
        
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    private lazy var container: NSPersistentContainer = {
        let persistentContainer = NSPersistentContainer(name: "CoreDataFeedStore", managedObjectModel: managedObjectModel)
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("Failed to load persistent stores with error: \(error)")
            }
        }
        
        return persistentContainer
    }()
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        let context = self.context
        context.perform {
            do {
                let managedCache = try context.fetch(ManagedCache.fetchRequest() as NSFetchRequest<ManagedCache>)
                
                if !managedCache.isEmpty {
                    let cache = managedCache.first!
                    completion(.found(feed: cache.managedFeedImages.map({$0.localFeedImage}), timestamp: cache.timestamp!))
                    
                } else {
                    completion(.empty)
                }
                
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        
        let context = self.context
        context.perform {
            do {
                let cache = try ManagedCache.UniqueCache(in: context)
                cache.timestamp = timestamp
                
                let managedFeedImages = feed.map { (image) -> ManagedFeedImage in
                    let managedFeedImage = ManagedFeedImage(context: context)
                    managedFeedImage.id = image.id
                    managedFeedImage.descriptions = image.description
                    managedFeedImage.location = image.location
                    managedFeedImage.url = image.url
                    return managedFeedImage
                }
                
                cache.addToFeed(NSOrderedSet(array: managedFeedImages))
                
                try context.save()
                completion(nil)
                
            } catch {
                completion(.some(error))
            }
        }
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        
        let context = self.context
        context.perform {
            do {
                let cache = try context.fetch(ManagedCache.fetchRequest() as NSFetchRequest<ManagedCache>)
                
                for item in cache {
                    context.delete(item)
                }
                
                try context.save()
                
                completion(nil)
            } catch {
                completion(.some(error))
            }
        }
    }
}

class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {
	
    //  ***********************
    //
    //  Follow the TDD process:
    //
    //  1. Uncomment and run one test at a time (run tests with CMD+U).
    //  2. Do the minimum to make the test pass and commit.
    //  3. Refactor if needed and commit again.
    //
    //  Repeat this process until all tests are passing.
    //
    //  ***********************

	func test_retrieve_deliversEmptyOnEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}

	func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}

	func test_insert_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()

		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}

	func test_insert_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}

	func test_insert_overridesPreviouslyInsertedCacheValues() {
		let sut = makeSUT()

		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}

	func test_delete_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()

		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}

	func test_delete_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()

		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}

	func test_delete_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()

		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}

	func test_delete_emptiesPreviouslyInsertedCache() {
		let sut = makeSUT()

		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}

	func test_storeSideEffects_runSerially() {
		let sut = makeSUT()

		assertThatSideEffectsRunSerially(on: sut)
	}
	
	// - MARK: Helpers
	
	private func makeSUT() -> FeedStore {
		return CoreDataFeedStore()
	}
	
}

//  ***********************
//
//  Uncomment the following tests if your implementation has failable operations.
//
//  Otherwise, delete the commented out code!
//
//  ***********************

//extension FeedStoreChallengeTests: FailableRetrieveFeedStoreSpecs {
//
//	func test_retrieve_deliversFailureOnRetrievalError() {
////		let sut = makeSUT()
////
////		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
//	}
//
//	func test_retrieve_hasNoSideEffectsOnFailure() {
////		let sut = makeSUT()
////
////		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
//	}
//
//}

//extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {
//
//	func test_insert_deliversErrorOnInsertionError() {
////		let sut = makeSUT()
////
////		assertThatInsertDeliversErrorOnInsertionError(on: sut)
//	}
//
//	func test_insert_hasNoSideEffectsOnInsertionError() {
////		let sut = makeSUT()
////
////		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
//	}
//
//}

//extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {
//
//	func test_delete_deliversErrorOnDeletionError() {
////		let sut = makeSUT()
////
////		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
//	}
//
//	func test_delete_hasNoSideEffectsOnDeletionError() {
////		let sut = makeSUT()
////
////		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
//	}
//
//}
