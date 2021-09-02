//
//  ViewController.swift
//  ARShooter
//
//  Created by Marko Jovanov on 2.9.21.
//

import UIKit
import SceneKit
import ARKit

enum BitMaskCategory: Int {
    case bullet = 2
    case target = 3
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    private var power: Float = 50
    private var targetNode: SCNNode?
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.autoenablesDefaultLighting = true
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    @IBAction func addTargets(_ sender: UIButton) {
        addEgg(x: 5, y: 0, z: -40)
        addEgg(x: 0, y: 0, z: -40)
        addEgg(x: -5, y: 0, z: -40)
    }
    func addEgg(x: Float,y: Float, z: Float) {
        if let eggScene = SCNScene(named: "egg.scn") {
            if let eggNode = eggScene.rootNode.childNode(withName: "egg",
                                                         recursively: false) {
                eggNode.position = SCNVector3(x,y,z)
                eggNode.physicsBody = SCNPhysicsBody(type: .static,
                                                     shape: SCNPhysicsShape(node: eggNode,
                                                                            options: nil))
                eggNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
                eggNode.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
                sceneView.scene.rootNode.addChildNode(eggNode)
            }
        }
    }
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneViewTap = sender.view as? ARSCNView else { return }
        guard let pointOfView = sceneViewTap.pointOfView else { return }
        let transform = pointOfView.transform
        let orientation = SCNVector3(
            -transform.m31,
            -transform.m32,
            -transform.m33
        )
        let location = SCNVector3(
            transform.m41,
            transform.m42,
            transform.m43
        )
        let position = orientation + location
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.1))
        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        bullet.position = position
        let body = SCNPhysicsBody(type: .dynamic,
                                  shape: SCNPhysicsShape(node: bullet,
                                                         options: nil))
        body.isAffectedByGravity = false
        bullet.physicsBody = body
        bullet.physicsBody?.applyForce(SCNVector3(orientation.x * power,
                                                  orientation.y * power,
                                                  orientation.z * power),
                                       asImpulse: true)
        bullet.physicsBody?.categoryBitMask = BitMaskCategory.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask  = BitMaskCategory.target.rawValue
        sceneView.scene.rootNode.addChildNode(bullet)
        bullet.runAction(SCNAction.sequence([SCNAction.wait(duration: 2.0),
                                             SCNAction.removeFromParentNode()]))
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            targetNode = nodeA
        } else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            targetNode = nodeB
        }
        if let spark = SCNParticleSystem(named: "art.scnassets/Fire.scnp", inDirectory: nil) {
            spark.loops = false
            spark.particleLifeSpan = 4
            spark.emitterShape = targetNode?.geometry
            let sparkNode = SCNNode()
            sparkNode.addParticleSystem(spark)
            sparkNode.position = contact.contactPoint
            sceneView.scene.rootNode.addChildNode(sparkNode)
        }
        targetNode?.removeFromParentNode()
    }
}
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
