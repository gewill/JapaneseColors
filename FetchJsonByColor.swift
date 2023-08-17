import Foundation

// 替换为您提供的标题数组
let titles = ["yellow", "green", "red", "purple", "blue", "pink", "brown", "orange", "black", "gray", "white"]

// 创建一个DispatchGroup以便等待所有请求完成
let group = DispatchGroup()

// 创建一个并发队列用于执行异步操作
let queue = DispatchQueue(label: "com.example.networkQueue", attributes: .concurrent)

// 创建一个URLSession对象
let session = URLSession.shared

// 循环遍历标题数组，进行异步网络请求和保存文件操作
for title in titles {
    group.enter()

    let urlStr = "https://colors.limboy.me/colors/s/\(title)?_data=routes%2Fcolors.s.%24series"
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
            let filePath = documentsPath.appendingPathComponent("\(title).json")

            // 将响应数据保存为文件
            do {
                try data.write(to: filePath)
                print("File saved for color \(title) at \(filePath)")
            } catch {
                print("Error writing file for color \(title): \(error)")
            }
        }
    }
    task.resume()
}

// 等待所有请求完成
group.wait()
