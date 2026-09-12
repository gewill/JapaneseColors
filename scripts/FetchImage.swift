import Foundation
import ImageIO

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(EXIT_FAILURE)
}

// 创建一个DispatchGroup以便等待所有请求完成
let group = DispatchGroup()

// 创建一个URLSession对象
let session = URLSession.shared

// 创建保存图片的文件夹路径
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let saveFolderPath = documentsPath.appendingPathComponent("images")

// 确保文件夹存在
do {
    try FileManager.default.createDirectory(at: saveFolderPath, withIntermediateDirectories: true, attributes: nil)
} catch {
    fail("Cannot create image directory: \(error)")
}

// 定义每个月的天数
let daysInMonths: [Int] = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

// 循环遍历月份和日子，进行异步网络请求和保存图片操作
for month in 1...12 {
    for day in 1...daysInMonths[month] {
        group.enter()

        let urlStr = "https://colors.limboy.me/images/\(month).\(day).jpg"
        guard let url = URL(string: urlStr) else {
            fail("Invalid image URL: \(urlStr)")
        }

        let task = session.dataTask(with: url) { data, response, error in
            defer { group.leave() }

            if let error = error {
                fail("Image request failed for \(month)/\(day): \(error)")
            }
            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode) else {
                fail("Image request failed for \(month)/\(day): \(String(describing: response))")
            }
            guard let data = data,
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  CGImageSourceGetType(source) as String? == "public.jpeg",
                  CGImageSourceGetStatus(source) == .statusComplete else {
                fail("Invalid JPEG for \(month)/\(day)")
            }
            do {
                // 构建文件路径
                let filePath = saveFolderPath.appendingPathComponent("\(month)_\(day).jpg")

                // 将图片数据保存为文件
                try data.write(to: filePath, options: .atomic)
                print("Image saved for \(month)/\(day) at \(filePath)")
            } catch {
                fail("Error writing image for \(month)/\(day): \(error)")
            }
        }
        task.resume()
    }
}

// 等待所有请求完成
group.wait()
