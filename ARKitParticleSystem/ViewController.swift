//
//  ViewController.swift
//  ARKitParticleSystem
//
//  Created by Roman Belov on 20.06.2022.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var planes = [Plane]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [.showFeaturePoints]
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        setupGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
}


//MARK: Gestures and objects
extension ViewController {
    func setupGesture() {
        
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(placeVirtualObject))
        sceneView.addGestureRecognizer(doubleTapGestureRecognizer)
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
    }
    
    @objc func placeVirtualObject(tapGesture: UITapGestureRecognizer) {
        self.sceneView.scene.removeAllParticleSystems()
        
        let sceneView = tapGesture.view as! ARSCNView
        let location = tapGesture.location(in: sceneView)
        
        let raycastQuery = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        guard let result = sceneView.session.raycast(raycastQuery!).first else { return }
        createVirtualObject(hitResult: result)
    }
    
    func createVirtualObject(hitResult: ARRaycastResult) {
        let position = SCNVector3(hitResult.worldTransform.columns.3.x,
                                  hitResult.worldTransform.columns.3.y,
                                  hitResult.worldTransform.columns.3.z)
        
        guard let virtualObject = VirtualObject.availableObjects.first else { fatalError("There is no virtual object available") }
        virtualObject.position = position
        virtualObject.load()
        
        if let smokeParticleSystem = SCNParticleSystem(named: "Smoke.scnp", inDirectory: nil), let smokeNode = virtualObject.childNode(withName: "SmokeNode", recursively: true) {
            smokeNode.addParticleSystem(smokeParticleSystem)
        }
           
        sceneView.scene.rootNode.addChildNode(virtualObject)
    }

}

//MARK: ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        
        let plane = Plane(anchor: anchor as! ARPlaneAnchor)
        
        planes.append(plane)
        node.addChildNode(plane)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        let plane = planes.filter { plane in
            return plane.anchor.identifier == anchor.identifier
        }.first
        
        guard plane != nil else { return }
        
        plane?.update(anchor: anchor as! ARPlaneAnchor)
    }
}

