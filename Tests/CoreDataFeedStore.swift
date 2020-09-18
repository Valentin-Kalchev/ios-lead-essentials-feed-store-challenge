//
//  CoreDataFeedStore.swift
//  Tests
//
//  Created by Valentin Kalchev (Zuant) on 18/09/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import FeedStoreChallenge 
import CoreData

class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(withModelName: "Model", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }
    
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
