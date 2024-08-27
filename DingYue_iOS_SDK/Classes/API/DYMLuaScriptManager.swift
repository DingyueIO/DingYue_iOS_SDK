//
//  DYMLuaScriptManager.swift
//  DingYue_iOS_SDK
//
//  Created by 王勇 on 2024/8/5.
//

import UIKit
import SSZipArchive
@objc public class DYMLuaScriptManager: NSObject {
     @objc public static let shared = DYMLuaScriptManager()
    //下载lua zip
   @objc public class func downloadLuaScriptZip(url: URL, completion:@escaping (SimpleStatusResult?,Error?) -> Void) {
        let zipUrl = url
        URLSession.shared.downloadTask(with: zipUrl) { url, response, error in
            
            if let error = error {
                print("dylua ---下载错误: \(error)")
            } else if let url = url {
                print("dylua ---下载完成, 文件路径: \(url)")
            }
            
            if response != nil {
                if (response as! HTTPURLResponse).statusCode == 200 {

                    if let zipFileUrl = url, let targetUnzipUrl = UserProperties.luaScriptDirectoryPath {
                        let success = SSZipArchive.unzipFile(atPath: zipFileUrl.path, toDestination: targetUnzipUrl)
                        if success {
                            var items: [String]
                              do {
                                  items = try FileManager.default.contentsOfDirectory(atPath: targetUnzipUrl)
                                  print("dylua --- 下载脚本Zip ok --- 解压缩ok \(items)")
                              } catch {
                               return
                              }
                        } else {
                            print("dylua --- 下载脚本Zip ok --- 解压缩失败")
                        }
                        try? FileManager.default.removeItem(at: zipFileUrl)
                    } else {
                        print("dylua --- 下载脚本Zip ok --- zip url or unzip url is nil")
                    }
                }else {
                    print("dylua --- 下载脚本Zip失败 --- status code != 200")
                }
            } else {
                print("dylua --- 下载脚本Zip失败 --- response == nil")
            }
        }.resume()
    }
    
    //获取lua 脚本文件路径
    //?? sdk 返回给客户端一个文件目录的路径，或者所有文件的路径 - 可以在里面放些别的配置文件使用
    @objc public class func getLuaScriptFiles() throws -> [URL] {
        if let luaDirURL = UserProperties.luaScriptDirectoryPath {
            let url = URL(fileURLWithPath: luaDirURL)
            let files = try FileManager.default.contentsOfDirectory(atPath: luaDirURL)
//            let luaFiles = files.filter { $0.hasSuffix(".lua") }
            let luaFilePaths = files.map { url.appendingPathComponent($0) }
            return luaFilePaths
        } else {
            return []
        }
    }
    
}
