# Aimless

The name Aimless is simply because I didn't have a particular aim when I started coding this app. 

## TL;DR
This is an app demonstrating an offline first approach, with a remote synchronization strategy. 

## Overview
This readme covers the following:
- Features
- Synchronization
- Synchronization of deleted items
- Arhitecture, patterns and technologies
- Additional thoughts

## Features
The app itself presents different todos, which can be created locally, or fetched from remote. Each todo item displays its current synchronization status, which can either be `notSynchronized`, `synchronizationPending` or `synchronized`. The todos can be deleted, and are subsequently moved to a 'Recently deleted' screen. On this screen they can either be permanently deleted or restored again. 

The api used for fetching remote todos is the [JSONPlaceholder API](https://jsonplaceholder.typicode.com/), which is a simple test API without 
any authorization requirments. 

## Synchronization

Before talking about the synchronization strategy, it is againg worth mentioning that a local item can be in three different states:
1. `notSynchronized`
2. `synchronizationPending`
3. `synchronized`

### The strategy:
1. Fetch all unsynced local change.
2. Update sync state of unsynced changes to `synchronizationPending`.
3. Perform remote sync.
4. Merge response from remote sync with local changes.
6. Update sync state of unsynced changes to `synchronized`.
7. Repeat every 20 seconds.

There are some checks happening when importing data from the server, which will not allow for overwriting of local todos with remote changes, if the local ones are not synchronized. Additionally, I only consider items whose deletion status is `notDeleted` (see next section for more info), all other items are not a part of this synchronization process.

## Synchronization of deleted items
With regards to deletions, there is a seperate synchronization happening. Each item can be in three different deletion states:
1. `notDeleted`
2. `deletionPending`
3. `deleted`

The first state, `notDeleted`, is self-explanitory. The item is not deleted, and is a 'regular' item. This item can change its state to a `deletionPending` item if a user performs a delete action on it. The `deletionPending` state is when an item is temporary deleted and moved to the 'Recently deleted' screen. On this screen, the item can either be restored, which will set its state back to `notDeleted` or permanently deleted, which will set its state to `deleted`. When the state is `deleted` the item will be permanently deleted in the next sync cycle.

### The strategy:
The synchronization strategy for deleted items is as follows:
1. Fetch all items whose status is `deleted`.
2. Sync deleted items to remote.
3. Delete items locally.
4. Repeat every 20 seconds.

## Arhitecture, testing and technologies
The code base is organised in local SPM modules, where each service and feature represents a distinct package. Apart from the obvious benefits, such as 
seperation of concern and loose coupling, there is also an added benefit of reduced build times, as each package has its own target, which means you don't have to build the whole application when you are only working in a specific module. This is also great for fast build of SwiftUI previews.

Each service is tested quite extensively. However because of time constraints, the view models are not, but they use code from the services which are tested. In order to achieve testing, I used patterns such as dependency injection, but I also tried to make sure that each function and class is as DRY and orthogonal as possible.

I have not used any non-Apple libraries or frameworks, but rather created my own wrappers when needed. For the persistence stack I used Core Data, where I created my own wrappers on top for convinience. The UI layer is made with SwiftUI and for most of my async work I used Apple's newest `async-await` and concurrency features. I also used `Combine` in a couple of places. 

## Aditional thoughts
SwiftUI has its own property wrapper called `@FetchRequest`, which can be used in combination with Core Data. I however decided not to do this, but rather create a wrapper around the standard `FetchedResultsController`. The primary reason for this is that the `@FetchRequest` is tightly coupled with the view layer, which in essence means that the Core Data stack is coupled to the view. This is no good with regards to seperation of concern, amongst other things.

