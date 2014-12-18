//
//  ViewController.m
//  CocoaheadsHBAsyncSearch
//
//  Created by Lincoln Six Echo on 21.10.14.
//  Copyright (c) 2014 appdoctors UG. All rights reserved.
//

#import "ViewController.h"

@interface SearchOperation : NSOperation

@property (nonatomic, weak) id<SearchOperationDelegate> delegate;
@property (nonatomic, copy) NSString *needle;
@property (nonatomic, copy) NSArray *haystack;

@end

@implementation SearchOperation

- (void)main {
	if ([self isCancelled]) {
		return;
	}
	
	NSMutableArray *myItemsFound = [NSMutableArray array];
	for(NSString *currentItem in self.haystack ) {
		NSString *stringToSearch = currentItem;
		if( [stringToSearch rangeOfString:self.needle options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)].location != NSNotFound ) {
			[myItemsFound addObject:currentItem];
		}
		if ([self isCancelled]) {
			return;
		}
	}
	
	if ([self isCancelled]) {
		return;
	}
	
	[self.delegate searchOperation:self didFindResults:myItemsFound];
}

@end

@interface ViewController ()

@property (nonatomic, strong) NSDate *lastSearchStartDate;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AV1611Bible" ofType:@"txt"];
    self.inMemoryBibleText = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
    self.resultsTextView.text = self.inMemoryBibleText;
    
    // WE JUST SPLIT THE BIBLE TEXT IN SNIPPETS OF CHARACTERS TO HAVE SOME DATA TO SEARCH FOR
    NSMutableArray *bibleTextSnippets = [NSMutableArray array];
    BOOL hasMoreText = YES;
    long currentLocation = 0;
    long snippetLength = 200;
    NSRange currentRange;
    NSString *currentSnippet = nil;
    while( hasMoreText ) {
        currentRange = NSMakeRange( currentLocation, snippetLength );
        @try {
            currentSnippet = [self.inMemoryBibleText substringWithRange:currentRange];
            [bibleTextSnippets addObject:currentSnippet];
            currentLocation += snippetLength;
        }
        @catch (NSException *exception) {
            hasMoreText = NO;
        }
    }
    self.inMemoryBibleTextSnippets = [NSArray arrayWithArray:bibleTextSnippets];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchFieldContentChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) usesGDCSearch {
    return self.searchSegmentedControl.selectedSegmentIndex == 0;
}

- (BOOL) usesNSOperationSearch {
    return ![self usesGDCSearch];
}

#pragma mark - user actions

- (IBAction) actionSearchTapped:(id)sender {
    [self.searchTextField resignFirstResponder];
    [self searchForStringAsync:self.searchTextField.text];
}

- (IBAction) actionSearchAlgorithmChanged:(UISegmentedControl*)sender {
    [self searchForStringAsync:self.searchTextField.text];
}

#pragma mark - search algorithms

// SOME STATUS VARIABLES WE NEED TO SYNTHESIZE
@synthesize isSearchInProgress;
@synthesize wantsAnotherSearch;
@synthesize stringToSearchForWhenCompleted;

- (void) refreshUiWithItemsFound:(NSArray*)itemsFound {
    // UPDATE YOUR UI HERE!
    NSMutableString *resultString = [NSMutableString string];
	NSTimeInterval searchTime = [[NSDate date] timeIntervalSinceDate:self.lastSearchStartDate];
    [resultString appendFormat:@"We found %lu hits in %.3fs\n\n", (unsigned long)[itemsFound count], searchTime];
    unsigned long index = 0;
    for( NSString *currentItem in itemsFound ) {
        index++;
        [resultString appendFormat:@"\n[%lu] — %@\n", index, currentItem];
    }
    self.resultsTextView.text = (NSString*)resultString;
}

- (void) searchForStringAsync:(NSString*)string {
    self.resultsLabel.text = [self usesGDCSearch] ? @"Grand Central Dispatch results" : @"NSOperation results";
	self.lastSearchStartDate = [NSDate date];
    if( !string || [string length] == 0 ) {
        [self refreshUiWithItemsFound:[NSArray array]];
        return;
    }
    
    if( [self usesGDCSearch] ) {  // WE USE GDC SEARCH
        if( isSearchInProgress ) {
            // IF ONE SEARCH-THREAD IS ALREADY IN PROGRESS DO NOT TRIGGER ANOTHER
            // INSTEAD STORE THE STRING AND REMEMER WE NEED ANOTHER SEARCH
            wantsAnotherSearch = YES;
            self.stringToSearchForWhenCompleted = string;
            return;
        }
        stringToSearchForWhenCompleted = nil;
        // REMEMBER WE HAVE OFFICIALLY HAVE A COMPUTING INTENSIVE
        // ACTION RUNNING ALREADY
        isSearchInProgress = YES;
        
        // WE JUST USE THE BIBLE TEXT SNIPPETS WE CREATED
        NSArray *itemsToSearch = self.inMemoryBibleTextSnippets;
        
        // STEP 0: CREATE YOUR THREADS QUEUE
        //         (THINK PACKAGING FOR YOUR JOB TICKET)
        dispatch_queue_t searchTextQueue;
        searchTextQueue = dispatch_queue_create("myFancySearchTextQueueJobId", DISPATCH_QUEUE_CONCURRENT);
        
        // CPU-CYCLES MEASURE NANOSECONDS SO WE
        // NEED TO BE VERY PRECISE HERE, D'OH!
        double pauseTimeInMilliseconds = 200.0;
        int64_t pauseTimeInNanoseconds = (int64_t)( pauseTimeInMilliseconds * NSEC_PER_MSEC );
        
        // STEP 1: GIVE SOME TIME TO MAIN THREAD FIRST (!!) I.E. KEYBOARD UI
        dispatch_time_t pauseTime = dispatch_time( DISPATCH_TIME_NOW, pauseTimeInNanoseconds );
        
        // STEP 2: SEND/DISPATCH OUR JOBTICKET TO OUR OWN THREAD QUEUE
        dispatch_after( pauseTime, searchTextQueue, ^(void) {
            NSMutableArray *myItemsFound = [NSMutableArray array];
            for( NSString* currentItem in itemsToSearch ) {
                NSString *stringToSearch = currentItem;
                if( [stringToSearch rangeOfString:string options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)].location != NSNotFound ) {
                    [myItemsFound addObject:currentItem];
                }
                if( wantsAnotherSearch ) {
                    // CANCEL SEARCH-FOR-LOOP BECAUSE WE HAVE NEW REQUEST
                    break;
                }
            }
            if( !wantsAnotherSearch ) { // SKIP UI REFRESH
                // STEP 3: COMMUNICATE RESULTS TO MAIN THREAD TO UPDATE THE UI
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refreshUiWithItemsFound:myItemsFound];
                });
            }
            // STEP 4: DO SOME CLEANUP AND CHECK IF WE NEED TO
            //         TRIGGER NEXT SEARCH IMMEDIATELY
            isSearchInProgress = NO;
            if( wantsAnotherSearch ) {
                wantsAnotherSearch = NO;
                [self searchForStringAsync:stringToSearchForWhenCompleted];
            }
        });
    }
    else { // WE USE NSOPERATION SEARCH
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			self.myOperationQueue = [NSOperationQueue new];
		});
		
		[self.myOperationQueue.operations makeObjectsPerformSelector:@selector(cancel)];
		
		SearchOperation *operation = [SearchOperation new];
		operation.delegate = self;
		operation.haystack = self.inMemoryBibleTextSnippets;
		operation.needle = string;
		[self.myOperationQueue addOperation:operation];
    }
}

#pragma mark - UITextField Delegate

- (void) searchFieldContentChanged:(NSNotification*)notification {
    [self searchForStringAsync:self.searchTextField.text];
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self searchForStringAsync:textField.text];
    return YES;
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    return YES;
}

- (BOOL) textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField { // SAME AS CLICKING SEARCH
    [textField resignFirstResponder];
    [self searchForStringAsync:textField.text];
    return YES;
}

- (void)searchOperation:(SearchOperation *)operation didFindResults:(NSArray *)results {
	[self performSelectorOnMainThread:@selector(refreshUiWithItemsFound:) withObject:results waitUntilDone:YES];
}

@end
