# Aimless

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
The app itself presents different todos, which can be created locally, or fetched from remote. Each todo item displays its current synchronization status, 
which can either be "Not synchronized", "Synchronization pending" or "Synchronized". The todos can be deleted, and are subsequently moved to a "Recently deleted" screen. 
On this screen they can either be permanently deleted
or restored again. 

The api used for fetching remote todos is the [JSONPlaceholder API](https://jsonplaceholder.typicode.com/), which is a simple test API without 
any authorization requirments. 

## Synchronization

Before talking about the synchronization strategy, it is againg worth mentioning that a local item can be in three different states:
1. Not synchronized
2. Synchronization pending
3. Synchronized

### The strategy:
1. Fetch all unsynced local changes
2. Update sync state of unsynced changes to 'synchronizationPending'.
3. Perform remote sync
4. Merge response from remote sync with local changes
6. Update sync state of unsynced changes to 'synchronized'
7. Repeat every 20 seconds

There are some checks happening when importing data from the server, which will not allow for overwriting of local todos with remote
changes, if the local ones are not synchronized. Additionally, I only consider items whose deletion status is 'Not deleted' (see next section for more info), 
all other items are not a part of this synchronization process.

## Synchronization of deleted items
With regards to deletions, there is a seperate synchronization happening. Each item can be in three different deletion states:
1. Not deleted
2. Deletion pending
3. Deleted

The first state, 'Not deleted', is self-explanitory. The item is not deleted, and is a 'regular' item. This item can change its state to a 
'Deletion pending' item if a user performs a delete action on it. The 'Deletion pending' state is when an item is temporary deleted and 
moved to the 'Recently deleted' screen. On this screen, the item can either be restored, which will set its state back to 'Not deleted' 
or permanently deleted, which will set its state to 'Deleted'. When the state is 'Deleted' the item will be permanently deleted on the next
sync cycle.

