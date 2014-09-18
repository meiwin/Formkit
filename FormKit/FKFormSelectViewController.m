//
//  FKFormSelectViewController.m
//  FormKit
//
//  Created by Hong Wei Zhuo on 18/9/14.
//  Copyright (c) 2014 ___zhuohongwei___. All rights reserved.
//

#import "FKFormSelectViewController.h"
#import "FKFormItem.h"

@interface FKFormSelectViewController () <UISearchBarDelegate, UISearchDisplayDelegate> {
    FKSelectFieldItem *_selectFieldItem;
    NSArray * _sortedKeyValues;
    
    UISearchBar * _searchBar;
    UISearchDisplayController * _searchDisplayController;
    NSMutableArray * _searchKeyValues;
}

-(void)back:(id)sender;

@end

@implementation FKFormSelectViewController

-(void)deriveSortedKeyValues
{
    NSMutableDictionary * reverseMap = [NSMutableDictionary dictionary];
    for (NSString * key in _selectFieldItem.keyAndDisplayValues)
    {
        reverseMap[_selectFieldItem.keyAndDisplayValues[key]] = key;
    }
    
    NSArray * sortedLabels = [[reverseMap allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray * sortedKeyValues = [NSMutableArray array];
    for (NSString * key in sortedLabels) [sortedKeyValues addObject:reverseMap[key]];
    _sortedKeyValues = sortedKeyValues;
}
-(id)initWithSelectFieldItem:(FKSelectFieldItem *)selectFieldItem {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _selectFieldItem = selectFieldItem;
        
        _sortedKeyValues = _selectFieldItem.sortedKeyValues;
        if (_sortedKeyValues == nil) [self deriveSortedKeyValues];
        
        _searchKeyValues = [NSMutableArray array];
        _allowSearching = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *backButton = [UIHelpers barButtonWithTitle:@"Back" target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 38)];
    _searchBar.backgroundImage = [UIImage imageNamed:@"bg_searchbar"];
    [_searchBar setSearchFieldBackgroundImage:[UIImage imageNamed:@"bg_searchbar_textfield"] forState:UIControlStateNormal];
    _searchBar.delegate = self;
    
    _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    _searchDisplayController.delegate = self;
    _searchDisplayController.searchResultsDataSource = self;
    _searchDisplayController.searchResultsDelegate = self;
    
    if (_allowSearching) {
        self.tableView.tableHeaderView = _searchBar;
    }
}

-(void)setAllowSearching:(BOOL)allowSearching {
    _allowSearching = allowSearching;
    if (self.isViewLoaded) {
        if (_allowSearching) {
            self.tableView.tableHeaderView = _searchBar;
        } else {
            self.tableView.tableHeaderView = nil;
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView == self.tableView) {
        if (_selectFieldItem && _sortedKeyValues) {
            return _sortedKeyValues.count;
        }
    } else if (tableView == _searchDisplayController.searchResultsTableView) {
        return _searchKeyValues.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    NSArray *keyValues = (tableView == self.tableView)? _sortedKeyValues:_searchKeyValues;
    id keyValue = [keyValues objectAtIndex:indexPath.row];
    
    NSString *displayValue = [_selectFieldItem.keyAndDisplayValues objectForKey:keyValue];
    displayValue = displayValue?displayValue:@"";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
        
        //        cell.textLabel.highlightedTextColor = [UIColor grayColor];
        
        UIView *selectedBackgroundView = [UIView new];
        selectedBackgroundView.backgroundColor = mRgb(0xea, 0xea, 0xea);
        cell.selectedBackgroundView = selectedBackgroundView;
    }
    
    cell.textLabel.text = displayValue;
    
    if (keyValue && _selectFieldItem.value && [keyValue isEqual:_selectFieldItem.value]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *keyValues = (tableView == self.tableView)? _sortedKeyValues:_searchKeyValues;
    id keyValue = [keyValues objectAtIndex:indexPath.row];
    
    if (!_selectFieldItem.value || (keyValue && _selectFieldItem.value && ![keyValue isEqual:_selectFieldItem.value])) {
        _selectFieldItem.value = keyValue;
        [_selectFieldItem reload];
        
        for (UITableViewCell *cell in tableView.visibleCells) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        FKForm *form = (FKForm *)_selectFieldItem.rootItem;
        [form valueChangedForItem:(ISInputItem *)_selectFieldItem];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - private methods

-(void)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    FKForm *form = (FKForm *)_selectFieldItem.rootItem;
    [form defocusItem:(ISInputItem *)_selectFieldItem];
}

#pragma mark - UISearchDelegate & UISearchDisplayDelegate

-(void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    UITableView *searchResultsTableView =  _searchDisplayController.searchResultsTableView;
    searchResultsTableView.backgroundColor = mRgb(0xf8, 0xf8, 0xfa);
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return YES;
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self performSearchWithTerm:searchBar.text];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self resetSearch];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self performSearchWithTerm:searchBar.text];
}

-(void)performSearchWithTerm:(NSString *)term {
    [self resetSearch];
    
    if (term.length == 0) {
        return;
    }
    
    NSArray *sortedValues = [_selectFieldItem.keyAndDisplayValues objectsForKeys:_sortedKeyValues notFoundMarker:[NSNull null]];
    
    [sortedValues enumerateObjectsUsingBlock:^(NSString *value, NSUInteger idx, BOOL *stop) {
        if ([value rangeOfString:term options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [_searchKeyValues addObject:_sortedKeyValues[idx]];
        }
    }];
}

-(void)resetSearch {
    [_searchKeyValues removeAllObjects];
}



@end
