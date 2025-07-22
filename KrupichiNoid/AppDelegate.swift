

import UIKit

@main
 class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


     func application(_ application: UIApplication,
           didFinishLaunchingWithOptions launchOptions:
           [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

           // 1. Создаем окно, но не отображаем контент сразу
           window = UIWindow(frame: UIScreen.main.bounds)
           
           // 2. Вместо немедленного отбражения игры — создаем "пустой" контроллер
           let blankVC = UIViewController()
           blankVC.view.backgroundColor = UIColor.white
           
           window?.rootViewController = blankVC
           window?.makeKeyAndVisible()

           // 3. Задержка 3 секунды — чтобы показать LaunchScreen дольше
           DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
               guard let self = self else { return }

               // 4. Создаем главный контроллер игры (например с SceneKit, SpriteKit и т.п.)
               let gameVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
               // Или если ты создаешь программно, сделай init нужного VC
               
               // 5. Показываем игровой контроллер вместо пустого
               self.window?.rootViewController = gameVC
           }

           return true
       }


    func applicationWillResignActive(_ application: UIApplication) {
       
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
      
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
       
    }


}

