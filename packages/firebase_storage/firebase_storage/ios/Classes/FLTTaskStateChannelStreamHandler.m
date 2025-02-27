// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <FirebaseStorage/FIRStorageTypedefs.h>

#import "FLTFirebaseStoragePlugin.h"
#import "FLTTaskStateChannelStreamHandler.h"

@implementation FLTTaskStateChannelStreamHandler {
  FIRStorageObservableTask *_task;

  FIRStorageHandle successHandle;
  FIRStorageHandle failureHandle;
  FIRStorageHandle pausedHandle;
  FIRStorageHandle progressHandle;
}

- (instancetype)initWithTask:(FIRStorageObservableTask *)task {
  self = [super init];
  if (self) {
    _task = task;
  }
  return self;
}

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
  // Set up the various status listeners
  successHandle =
      [_task observeStatus:FIRStorageTaskStatusSuccess
                   handler:^(FIRStorageTaskSnapshot *snapshot) {
                     events(@{
                       @"taskState" : @(PigeonStorageTaskStateSuccess),
                       @"appName" : snapshot.reference.storage.app.name,
                       @"snapshot" : [FLTFirebaseStoragePlugin parseTaskSnapshot:snapshot],
                     });
                   }];
  failureHandle =
      [_task observeStatus:FIRStorageTaskStatusFailure
                   handler:^(FIRStorageTaskSnapshot *snapshot) {
                     events(@{
                       @"taskState" : @(PigeonStorageTaskStateError),
                       @"appName" : snapshot.reference.storage.app.name,
                       @"error" : [FLTFirebaseStoragePlugin NSDictionaryFromNSError:snapshot.error],
                     });
                   }];
  pausedHandle =
      [_task observeStatus:FIRStorageTaskStatusPause
                   handler:^(FIRStorageTaskSnapshot *snapshot) {
                     events(@{
                       @"taskState" : @(PigeonStorageTaskStatePaused),
                       @"appName" : snapshot.reference.storage.app.name,
                       @"snapshot" : [FLTFirebaseStoragePlugin parseTaskSnapshot:snapshot],
                     });
                   }];
  progressHandle =
      [_task observeStatus:FIRStorageTaskStatusProgress
                   handler:^(FIRStorageTaskSnapshot *snapshot) {
                     events(@{
                       @"taskState" : @(PigeonStorageTaskStateRunning),
                       @"appName" : snapshot.reference.storage.app.name,
                       @"snapshot" : [FLTFirebaseStoragePlugin parseTaskSnapshot:snapshot],
                     });
                   }];

  return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
  if (!_task) {
    return nil;
  }

  if (successHandle) {
    [_task removeObserverWithHandle:successHandle];
  }
  successHandle = nil;

  if (failureHandle) {
    [_task removeObserverWithHandle:failureHandle];
  }
  failureHandle = nil;

  if (pausedHandle) {
    [_task removeObserverWithHandle:pausedHandle];
  }
  pausedHandle = nil;

  if (progressHandle) {
    [_task removeObserverWithHandle:progressHandle];
  }
  progressHandle = nil;

  return nil;
}

@end
