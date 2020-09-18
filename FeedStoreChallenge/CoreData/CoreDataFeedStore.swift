//
//  CoreDataFeedStore.swift
//  Tests
//
//  Created by Valentin Kalchev (Zuant) on 18/09/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(withModelName: "Model", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
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
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        
        let context = self.context
        context.perform {
            do {
                let cache = try ManagedCache.UniqueCache(in: context)
                cache.timestamp = timestamp
                cache.feed = ManagedFeedImage.feed(from: feed, with: context)
                
                try context.save()
                completion(nil)
                
            } catch {
                completion(.some(error))
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        
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

private extension ManagedCache {
    var managedFeedImages: [ManagedFeedImage] {
        return feed?.array as? [ManagedFeedImage] ?? []
    }
    
    static func UniqueCache(in context: NSManagedObjectContext) throws -> ManagedCache {
        let cache = try context.fetch(ManagedCache.fetchRequest() as NSFetchRequest<ManagedCache>)
        
        cache.forEach({ (item) in
            context.delete(item)
        })
        
        return ManagedCache(context: context)
    }
}

private extension ManagedFeedImage {
    var localFeedImage: LocalFeedImage {
        return LocalFeedImage(id: id!, description: descriptions, location: location, url: url!)
    }
    
    static func feed(from images: [LocalFeedImage], with context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: images.map { (image) -> ManagedFeedImage in
            let managedFeedImage = ManagedFeedImage(context: context)
            managedFeedImage.id = image.id
            managedFeedImage.descriptions = image.description
            managedFeedImage.location = image.location
            managedFeedImage.url = image.url
            return managedFeedImage
        })
    }
}
