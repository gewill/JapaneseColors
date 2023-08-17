import Foundation

// 创建一个DispatchGroup以便等待所有请求完成
let group = DispatchGroup()

// 创建一个并发队列用于执行异步操作
let queue = DispatchQueue(label: "com.example.networkQueue", attributes: .concurrent)

// 创建一个URLSession对象
let session = URLSession.shared

// 循环遍历月份，进行异步网络请求和保存文件操作
for month in 1...12 {
    group.enter()

    let urlStr = "https://colors.limboy.me/colors/d/\(month)?_data=routes%2Fcolors.d.$month"
    guard let url = URL(string: urlStr) else {
        group.leave()
        continue
    }

    let task = session.dataTask(with: url) { data, response, error in
        defer { group.leave() }

        if let data = data {
            // 获取Document目录路径
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            // 构建文件路径
            let filePath = documentsPath.appendingPathComponent("\(month).json")

            // 将响应数据保存为文件
            do {
                try data.write(to: filePath)
                print("File saved for month \(month) at \(filePath)")
            } catch {
                print("Error writing file for month \(month): \(error)")
            }
        }
    }
    task.resume()
}

// 等待所有请求完成
group.wait()
