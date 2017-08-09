//
//  ViewController.swift
//  SwiftFmdbDemo
//
//  Created by zhanfeng on 2017/8/8.
//  Copyright © 2017年 lzf. All rights reserved.
//

import UIKit


class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    let user = User()

    @IBOutlet weak var tableView: UITableView!
    var dataArray = [User]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user.name = "麦迪"
        user.age = 26
        user.sex = true
        user.greed = 100.0
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func insertOne(_ sender: UIButton) {
        user.insert()
    }
    
    @IBAction func insertMore(_ sender: Any) {
        User.insertWithArray(dataArray: [user,user,user])
        updateQueryData()
    }
    @IBAction func updateData(_ sender: Any) {
    }
    
    @IBAction func dateData(_ sender: Any) {
    }
    
    @IBAction func clearTable(_ sender: Any) {
    }
    @IBAction func queryAllData(_ sender: Any) {
        updateQueryData()
    }
    func updateQueryData() {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.backgroundColor = UIColor.randomColor
        let user = dataArray[indexPath.row]
        let string = "id:\(user.id)|name:\(user.name)|age:\(user.age)|sex:\(user.sex)"
        cell.textLabel?.text = string
        return cell
    }
}

class User: DBModel {
    var name:String = "feng"
    var age:Int = 0
    var sex:Bool = false
    var greed:Float = 0.0
    
    override init() {
        super.init()
        
    }
}

extension UIColor {
    //返回随机颜色
    class var randomColor: UIColor {
        get {
            let red = CGFloat(arc4random()%256)/255.0
            let green = CGFloat(arc4random()%256)/255.0
            let blue = CGFloat(arc4random()%256)/255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
    }
}


