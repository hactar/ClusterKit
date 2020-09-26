// CKCluster.m
//
// Copyright © 2017 Hulab. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <MapKit/MKGeometry.h>

#import "CKCluster.h"

double CKDistance(CLLocationCoordinate2D from, CLLocationCoordinate2D to) {
    MKMapPoint a = MKMapPointForCoordinate(from);
    MKMapPoint b = MKMapPointForCoordinate(to);
    return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);
}

MKMapRect MKMapRectByAddingPoint(MKMapRect rect, MKMapPoint point) {    
    return MKMapRectUnion(rect, (MKMapRect) {
        .origin = point,
        .size = MKMapRectNull.size
    });
}

NSComparisonResult MKMapSizeCompare(MKMapSize size1, MKMapSize size2) {
    double area1 = size1.width * size1.height;
    double area2 = size2.width * size2.height;
    if (area1 < area2) {
        return NSOrderedAscending;
    }
    if (area1 > area2) {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
}

@implementation CKCluster {
@protected
    NSMutableOrderedSet<id<MKAnnotation>> *_annotations;
    
    MKMapRect _bounds;
    BOOL _invalidate_bounds;
    
    
    
}

@synthesize coordinate = _coordinate;
static Class clusterClass;

- (instancetype)init{
    self = [super init];
    if (self) {
        _annotations = [[NSMutableOrderedSet orderedSet] retain];
        _coordinate = kCLLocationCoordinate2DInvalid;
        _bounds = MKMapRectNull;
        _invalidate_bounds = NO;
        clusterClass = [CKCluster class];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
    [_annotations release];
}

- (NSArray<id<MKAnnotation>> *)annotations {
    return _annotations.array;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    _coordinate = newCoordinate;
}

- (MKMapRect)bounds {
    if (_invalidate_bounds) {
        _bounds = MKMapRectNull;
        for (id<MKAnnotation> annotation in _annotations) {
            _bounds = MKMapRectByAddingPoint(_bounds, MKMapPointForCoordinate(annotation.coordinate));
        }
        
        _invalidate_bounds = NO;
    }
    return _bounds;
}

- (NSUInteger)count {
    return _annotations.count;
}

- (id<MKAnnotation>)firstAnnotation {
    return _annotations.firstObject;
}

- (void)addAnnotation:(id<MKAnnotation>)annotation {
    [_annotations addObject:annotation];
    _bounds = MKMapRectByAddingPoint(_bounds, MKMapPointForCoordinate(annotation.coordinate));
}

- (void)removeAnnotation:(id<MKAnnotation>)annotation {
    if ([_annotations containsObject:annotation]) {
        [_annotations removeObject:annotation];
        _invalidate_bounds = YES;
    }
}

- (BOOL)containsAnnotation:(id<MKAnnotation>)annotation {
    return [_annotations containsObject:annotation];
}

- (NSUInteger)hash {
    return _annotations.hash;
}

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:clusterClass]) {
        return NO;
    }
    return [self isEqualToCluster:object];
}

- (BOOL)isEqualToCluster:(CKCluster *)cluster {
    //    if (_annotations.count != cluster->_annotations.count) {
    //        return false;
    //    }
    
    __block bool differenceFound = false;
    [_annotations enumerateObjectsUsingBlock:^(id<MKAnnotation>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __block BOOL blockstop = false;
        [cluster->_annotations enumerateObjectsUsingBlock:^(id<MKAnnotation>  _Nonnull obj2, NSUInteger idx2, BOOL * _Nonnull stop2) {
            if (obj.coordinate.latitude != obj2.coordinate.latitude) {
                differenceFound = true;
                blockstop = true;
                stop2 = true;
                
            }
        }];
        stop = blockstop;

    }];
    return !differenceFound;
    //return [_annotations isEqual:cluster->_annotations];
}


- (BOOL)intersectsCluster:(CKCluster *)cluster {
    return [_annotations intersectsSet:cluster->_annotations];
}

- (BOOL)isSubsetOfCluster:(CKCluster *)cluster {
    return [_annotations isSubsetOfSet:cluster->_annotations];
}

#pragma mark <CKCluster>

+ (CKCluster *)clusterWithCoordinate:(CLLocationCoordinate2D)coordinate {
    CKCluster *cluster = [[self alloc] init];
    cluster.coordinate = coordinate;
    return cluster;
}

#pragma mark <MKAnnotation>

- (NSString *)title {
    if (_annotations.count == 1 && [_annotations.firstObject respondsToSelector:@selector(title)]) {
        return _annotations.firstObject.title;
    }
    return nil;
}

- (NSString *)subtitle {
    if (_annotations.count == 1 && [_annotations.firstObject respondsToSelector:@selector(subtitle)]) {
        return _annotations.firstObject.subtitle;
    }
    return nil;
}

@end

#pragma mark - Centroid Cluster

@implementation CKCentroidCluster

- (void)addAnnotation:(id<MKAnnotation>)annotation {
    [super addAnnotation:annotation];
    self.coordinate = [self coordinateByAddingAnnotation:annotation];
}

- (void)removeAnnotation:(id<MKAnnotation>)annotation {
    if ([_annotations containsObject:annotation]) {
        [_annotations removeObject:annotation];
        _invalidate_bounds = YES;
        self.coordinate = [self coordinateByRemovingAnnotation:annotation];
    }
}

- (CLLocationCoordinate2D)coordinateByAddingAnnotation:(id<MKAnnotation>)annotation {
    if (self.count < 2) {
        return annotation.coordinate;
    }
    
    CLLocationDegrees latitude = self.coordinate.latitude * (self.count - 1);
    CLLocationDegrees longitude = self.coordinate.longitude * (self.count - 1);
    latitude += annotation.coordinate.latitude;
    longitude += annotation.coordinate.longitude;
    
    return CLLocationCoordinate2DMake(latitude / self.count, longitude / self.count);
}

- (CLLocationCoordinate2D)coordinateByRemovingAnnotation:(id<MKAnnotation>)annotation {
    if (self.count < 1) {
        return kCLLocationCoordinate2DInvalid;
    }
    
    CLLocationDegrees latitude = self.coordinate.latitude * (self.count + 1);
    CLLocationDegrees longitude = self.coordinate.longitude * (self.count + 1);
    latitude -= annotation.coordinate.latitude;
    longitude -= annotation.coordinate.longitude;
    
    return CLLocationCoordinate2DMake(latitude / self.count, longitude / self.count);
}


@end

