import Foundation

// 创建一个DispatchGroup以便等待所有请求完成
let group = DispatchGroup()

// 创建一个并发队列用于执行异步操作
let queue = DispatchQueue(label: "com.example.networkQueue", attributes: .concurrent)

// 创建一个URLSession对象
let session = URLSession.shared

// 创建保存图片的文件夹路径
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let saveFolderPath = documentsPath.appendingPathComponent("images")

// 确保文件夹存在
try? FileManager.default.createDirectory(at: saveFolderPath, withIntermediateDirectories: true, attributes: nil)

// 定义每个月的天数
let daysInMonths: [Int] = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

// 循环遍历月份和日子，进行异步网络请求和保存图片操作
for month in 1...12 {
    for day in 1...daysInMonths[month] {
        group.enter()

        let urlStr = "https://colors.limboy.me/images/\(month).\(day).jpg"
        guard let url = URL(string: urlStr) else {
            group.leave()
            continue
        }

        let task = session.dataTask(with: url) { data, response, error in
            defer { group.leave() }

            if let data = data {
                // 构建文件路径
                let filePath = saveFolderPath.appendingPathComponent("\(month)_\(day).jpg")

                // 将图片数据保存为文件
                do {
                    try data.write(to: filePath)
                    print("Image saved for \(month)/\(day) at \(filePath)")
                } catch {
                    print("Error writing image for \(month)/\(day): \(error)")
                }
            }
        }
        task.resume()
    }
}

// 等待所有请求完成
group.wait()
