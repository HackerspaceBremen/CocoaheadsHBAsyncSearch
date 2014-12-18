//
//  ViewController.h
//  CocoaheadsHBAsyncSearch
//
//  Created by Lincoln Six Echo on 21.10.14.
//  Copyright (c) 2014 appdoctors UG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SearchOperation;

@protocol SearchOperationDelegate <NSObject>

- (void)searchOperation:(SearchOperation *)operation didFindResults:(NSArray *)results;

@end

@interface ViewController : UIViewController <UITextFieldDelegate, SearchOperationDelegate> {

    BOOL isSearchInProgress;
    BOOL wantsAnotherSearch;
    NSString *stringToSearchForWhenCompleted;

}

@property (strong, nonatomic) NSOperationQueue *myOperationQueue;

@property ( nonatomic, assign ) BOOL isSearchInProgress;
@property ( nonatomic, assign ) BOOL wantsAnotherSearch;
@property ( nonatomic, strong ) NSString *stringToSearchForWhenCompleted;

@property( nonatomic, strong ) IBOutlet UITextField *searchTextField;
@property( nonatomic, strong ) IBOutlet UITextView *resultsTextView;
@property( nonatomic, strong ) IBOutlet UISegmentedControl *searchSegmentedControl;
@property( nonatomic, strong ) IBOutlet UILabel *resultsLabel;
@property( nonatomic, strong ) NSString *inMemoryBibleText;
@property( nonatomic, strong ) NSArray *inMemoryBibleTextSnippets;

@end

