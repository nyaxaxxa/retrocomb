//
//  GameViewController.swift
//  retrocomb
//
//  Created by Алексей on 07.11.2025.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    private var hasPresentedScene = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let view = self.view as? SKView else { return }
        
        view.ignoresSiblingOrder = true

        #if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
        // view.showsPhysics = true
        // view.showsDrawCount = true
        #else
        view.showsFPS = false
        view.showsNodeCount = false
        view.showsPhysics = false
        view.showsDrawCount = false
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentMenuSceneIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        presentMenuSceneIfNeeded()
    }
    
    private func presentMenuSceneIfNeeded() {
        guard !hasPresentedScene, let view = self.view as? SKView else { return }
        
        // Проверяем, что размер view валидный
        var viewSize = view.bounds.size
        
        // Если размер view еще не готов (0 или очень маленький), используем размер экрана
        if viewSize.width <= 0 || viewSize.height <= 0 {
            viewSize = UIScreen.main.bounds.size
        }
        
        // Дополнительная проверка - если размер все еще невалидный, ждем следующего вызова
        guard viewSize.width > 0 && viewSize.height > 0 else {
            return
        }
        
        // Создаем сцену только если её еще нет
        if view.scene == nil {
            let scene = MenuScene(size: viewSize)
            scene.scaleMode = .resizeFill
            view.presentScene(scene)
            hasPresentedScene = true
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .portrait
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}
