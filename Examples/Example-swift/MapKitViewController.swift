// MapKitViewController.swift
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

import UIKit
import MapKit
import ClusterKit
import ExampleData

public let CKMapViewDefaultAnnotationViewReuseIdentifier = "annotation"
public let CKMapViewDefaultClusterAnnotationViewReuseIdentifier = "cluster"

class MapKitViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
     
    override func viewDidLoad() {
        super.viewDidLoad()

        let algorithm = CKNonHierarchicalDistanceBasedAlgorithm()
        algorithm.cellSize = 200
        
        mapView.clusterManager.algorithm = algorithm
        mapView.clusterManager.marginFactor = 1
        
        let paris = CLLocationCoordinate2D(latitude: 48.853, longitude: 2.35)
        mapView.setCenter(paris, animated: false)
        
        loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadData() {
        let operation = CKGeoPointOperation()
        
        operation.setCompletionBlockWithSuccess({ (_, points) in
            self.mapView.clusterManager.annotations = points
        })
        
        operation.start()
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let cluster = annotation as? CKCluster else {
            return nil
        }
        
        if cluster.count > 1 {
            return mapView.dequeueReusableAnnotationView(withIdentifier: CKMapViewDefaultClusterAnnotationViewReuseIdentifier) ??
                CKClusterView(annotation: annotation, reuseIdentifier: CKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        }
        
        return mapView.dequeueReusableAnnotationView(withIdentifier: CKMapViewDefaultAnnotationViewReuseIdentifier) ??
            CKAnnotationView(annotation: annotation, reuseIdentifier: CKMapViewDefaultAnnotationViewReuseIdentifier)
    }
    
    // MARK: - How To Update Clusters
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapView.clusterManager.updateClustersIfNeeded()
    }
    
    // MARK: - How To Handle Selection/Deselection
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let cluster = view.annotation as? CKCluster else {
            return
        }
        
        if cluster.count > 1 {
            let edgePadding = UIEdgeInsets.init(top: 40, left: 20, bottom: 44, right: 20)
            mapView.show(cluster, edgePadding: edgePadding, animated: true)
        } else if let annotation = cluster.firstAnnotation {
            mapView.clusterManager.selectAnnotation(annotation, animated: false);
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let cluster = view.annotation as? CKCluster, cluster.count == 1 else {
            return
        }
        
        mapView.clusterManager.deselectAnnotation(cluster.firstAnnotation, animated: false);
    }
    
    // MARK: - How To Handle Drag and Drop
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        guard let cluster = view.annotation as? CKCluster else {
            return
        }
        
        switch newState {
        case .ending:
            
            if let annotation = cluster.firstAnnotation as? MKPointAnnotation {
                annotation.coordinate = cluster.coordinate
            }
            view.setDragState(.none, animated: true)
            
        case .canceling:
            view.setDragState(.none, animated: true)
            
        default: break
            
        }
    }
}

class CKAnnotationView: MKAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = true
        isDraggable = true
        image = UIImage(named: "marker")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

class CKClusterView: MKAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        image = UIImage(named: "cluster")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}
