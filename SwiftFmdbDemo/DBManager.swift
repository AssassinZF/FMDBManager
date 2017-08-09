//
//  DBManager.swift
//  SwiftFmdbDemo
//
//  Created by zhanfeng on 2017/8/8.
//  Copyright © 2017年 lzf. All rights reserved.
//

import Foundation

fileprivate let defaultPath = "defaultDataBase"//default sqlite path name

class DBManager {
    //MARK:创建单例对象
    static let shared: DBManager = DBManager()
    
    fileprivate var dataBasePath = DBManager.defaultDataBasePath()
    
    public lazy var dataBaseQueue:FMDatabaseQueue = {
        let dbqueue = FMDatabaseQueue(path: DBManager.shared.dataBasePath)
        print("数据库路径:\(DBManager.shared.dataBasePath)")
        return dbqueue
    }()
    
    //MARK:配置数据库路径，默认为默认路径名
    public var configureDatabasePath:String{
        set{
            if !FileManager.default.fileExists(atPath: dataBasePath) {
                dataBasePath = newValue
            }
        }
        get{
            return dataBasePath
        }
    }

    private class func defaultDataBasePath() -> String{
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let path = documentDirectory.appending("/\(defaultPath)")
        return path
    }
}
