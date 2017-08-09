//
//  DBModel.swift
//  SwiftFmdbDemo
//
//  Created by zhanfeng on 2017/8/8.
//  Copyright © 2017年 lzf. All rights reserved.
//

import Foundation


let KPropertyName = "KPropertyName"
let KPropertyType  = "KPropertyType"
let kPrimaryType = "primary key"
let kPrimaryId = "id"

class DBModel: NSObject {
    var id:Int = 0 //主键
    
    private var columeNames = [String]()
    private var columeTypes = [String]()
    override init() {
        super.init()
        let result = getPropertys()
        columeNames = result[KPropertyName]!
        columeTypes = result[KPropertyType]!
    }
    
    //MARK:如果需要自定义表名，子类重写该方法返回类名
    class func customTableName() -> String? {
        return nil
    }
    
    //MARK:不行存储的属性列表
    func ignorePropertys() -> [String]? {
        return nil
    }
    
    //MARK:获取class 所有属性
    private func getPropertys() -> [String:[String]] {
        var propertyNames = [String]()
        var propertyTypes = [String]()
        let ignorePropertys = self.ignorePropertys()
        var count: UInt32 = 0
        let properties = class_copyPropertyList(type(of: self), &count)
        
        for i in 0..<count {
            let property = properties?[Int(i)]
            let name = property_getName(property)
            let pn = String.init(cString: name!)
            if ignorePropertys?.contains(pn) == true {
                continue
            }
            propertyNames.append(pn)
            let att = property_getAttributes(property)
            let attString = String.init(cString: att!)
            /*
             各种符号对应类型，部分类型在新版SDK中有所变化，如long 和long long
             c char         C unsigned char
             i int          I unsigned int
             l long         L unsigned long
             s short        S unsigned short
             d double       D unsigned double
             f float        F unsigned float
             q long long    Q unsigned long long
             B BOOL
             @ 对象类型 //指针 对象类型 如NSString 是@“NSString”
             
             
             64位下long 和long long 都是Tq
             SQLite 默认支持五种数据类型TEXT、INTEGER、REAL、BLOB、NULL
             因为在项目中用的类型不多，故只考虑了少数类型
             */
            if attString.hasPrefix("T@\"NSString\"") {
                propertyTypes.append(SQLType.TEXT.rawValue)
            }else if attString.hasPrefix("T@\"NSData\""){
                propertyTypes.append(SQLType.BLOB.rawValue)
            }else if attString.hasPrefix("Tq") ||
                attString.hasPrefix("Td") ||
                attString.hasPrefix("Tf"){
                propertyTypes.append(SQLType.INTEGER.rawValue)
            }else{
                propertyTypes.append(SQLType.REAL.rawValue)
            }
            
        }
        free(properties)
        return [KPropertyName:propertyNames,KPropertyType:propertyTypes]
    }
    
    //MARK:包括主键的所有属性
    private func getAllPropertys() ->[String:[String]]{
        var propertyDic = getPropertys()
        var name = propertyDic[KPropertyName]
        var type = propertyDic[KPropertyType]
        
        name?.insert(kPrimaryId, at: 0)
        type?.insert(kPrimaryType, at: 0)
        
        propertyDic[KPropertyName] = name
        propertyDic[KPropertyType] = type
        return propertyDic
    }
    
    //MARK:是否存在该表
    func isExist() -> Bool {
        var isExist = false
        
        let subClass = type(of: self)
        DBManager.shared.dataBaseQueue.inDatabase{(db) in
            isExist = db.tableExists(subClass.getTableName())
        }
        return isExist
    }
    
    //MARK:创建表
    func creatTable() -> Bool {
        if isExist() {
            return true
        }
        var res = true
        let subClass = type(of: self)
        DBManager.shared.dataBaseQueue.inDatabase{(db) in
            let tableName = subClass.getTableName()
            let columeAndType = self.getColumeAndType()
            let sql:String = "CREATE TABLE IF NOT EXISTS \(tableName)(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT ,\(columeAndType));"
            print("创建表——sql:\(sql)")
            let flag = db.executeStatements(sql)
            if !flag {
                res = flag
                return
            }
            print("创建表：\(tableName) => 成功")
        }
        return res
    }
    
    //MARK:插入数据
    @discardableResult
    func insert() -> Bool {
        if !creatTable() {
            return false
        }
        var keyStrings = ""
        var valueStrings = ""
        var insertValue = [Any]()
        
        for index in 0..<columeNames.count {
            let propertyName = columeNames[index]
            keyStrings.append("\(propertyName),")
            valueStrings.append("?,")
            var value = self.value(forKey: propertyName)
            if (value == nil){
                value = ""
            }
            insertValue.append(value ?? "")
        }
        let end = keyStrings.index(keyStrings.endIndex, offsetBy: -1)
        keyStrings = keyStrings.substring(to: end)
        
        let end1 = valueStrings.index(valueStrings.endIndex, offsetBy: -1)
        valueStrings = valueStrings.substring(to: end1)
        
        var res = false
        let subClass = type(of: self)
        DBManager.shared.dataBaseQueue.inDatabase { (db) in
            let sql = "INSERT INTO \(subClass.getTableName())(\(keyStrings)) VALUES (\(valueStrings));"
            print("插入sql:=>\(sql)\n")
            
            do {
                try db.executeUpdate(sql, values: insertValue)
                // 获取插入数据的主键
                let id = db.lastInsertRowId
                self.id = Int(id)
                print("插入数据的id: \(id)")
                res = true
                
            } catch let error as NSError {
                print("error: \(error)")
            }
            
//            res = db.executeUpdate(sql, withArgumentsIn: insertValue)
//            self.id = Int(db.lastInsertRowId)
            print(res ? "插入成功" : "插入失败")
        }
        return res
    }
    
    //MARK:批量插入数据
    @discardableResult
    class func insertWithArray(dataArray:[DBModel]) -> Bool {
        var res = false
        DBManager.shared.dataBaseQueue.inTransaction { (db, rollback) in
            for item in dataArray{
                var keyStrings = ""
                var valueStrings = ""
                var insertValue = [Any]()
                
                for index in 0..<item.columeNames.count {
                    let propertyName = item.columeNames[index]
                    keyStrings.append("\(propertyName),")
                    valueStrings.append("?,")
                    var value = self.value(forKey: propertyName)
                    if (value == nil){
                        value = ""
                    }
                    insertValue.append(value ?? "")
                }
                let end = keyStrings.index(keyStrings.endIndex, offsetBy: -1)
                keyStrings = keyStrings.substring(to: end)
                
                let end1 = valueStrings.index(valueStrings.endIndex, offsetBy: -1)
                valueStrings = valueStrings.substring(to: end1)
                
                let subClass = type(of: item)
                
                let sql = "INSERT INTO \(subClass.getTableName())(\(keyStrings)) VALUES (\(valueStrings));"
                print("插入sql:=>\(sql)\n")
                res = db.executeUpdate(sql, withArgumentsIn: insertValue)
                item.id = Int(db.lastInsertRowId)
                print(res ? "批插入成功" : "批插入失败")
            }
        }
        
        return res
    }
    
    //MARK:更新单个对象
    func update() -> Bool {
        return false
    }
    
    //MARK:查询数据
    class func queryAllData() -> [DBModel] {
        
//        DBManager.shared.dataBaseQueue.inDatabase { (db) in
//            do {
//                // 查询sql语句
//                let subClass = type(of: self)
//                let sql = "SELECT * FROM \(getTableName()) LIMIT ?;"
//                let result = try db.executeQuery(sql, values: [])
//                
//                while result.next() {
//                    // 通过字段名称获取字段值
//                    let item = subClass()
//                    
//                    let id = result.intForColumn("id")
//                    
//                    let name = result.stringForColumn("name")
//                    
//                    let age = result.intForColumn("age")
//                    
//                    let height = result.doubleForColumn("height")
//                    
//                    print("id: \(id), name: \(name), age: \(age), height: \(height)")
//                    print("------------")
//                }
//            } catch let error as NSError {
//                print("error: \(error)")
//            }

//        }
        return []
    }
    
    //MARK:请空表
    @discardableResult
    class func clearTable() -> Bool {
        var res = false
        DBManager.shared.dataBaseQueue.inDatabase { (db) in
            let tableName = getTableName()
            res = db.executeUpdate("DELETE FROM \(tableName)", withArgumentsIn: [])
        }
        return res
    }
    
    //MARK:获取表名称
    class func getTableName() -> String{
        let tableName = customTableName()
        if let tn = tableName {
            return tn
        }
        return self.className
        
    }
    
    func getColumeAndType() -> String {
        var pars:String = ""
        let dic = getPropertys()
        let propertyNames = dic[KPropertyName]
        let propertyArr = dic[KPropertyType]
        
        for index in 0..<Int((propertyNames?.count)!) {
            pars = pars + (propertyNames?[index])! + " " + (propertyArr?[index])!
            if index+1 != propertyNames?.count {
                pars += ","
            }
        }
        return pars
    }

    
}

/*
 * SQL数据了支持类型
 */
fileprivate enum SQLType:String{
    case TEXT = "TEXT"//文本
    case INTEGER = "INTEGER"//整型
    case REAL = "REAL" //浮点数
    case BLOB = "BLOB" //二进制
    case NULL = "NULL" //空值
}

extension NSObject{
    var className: String {
        return String(describing: type(of: self))
    }
    
    class var className: String {
        return String(describing: self)
    }
}
