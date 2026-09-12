import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(EXIT_FAILURE)
}

// 替换为您提供的标题数组
let titles = ["yellow", "green", "red", "purple", "blue", "pink", "brown", "orange", "black", "gray", "white"]

// 创建一个DispatchGroup以便等待所有请求完成
let group = DispatchGroup()

// 创建一个URLSession对象
let session = URLSession.shared

// 循环遍历标题数组，进行异步网络请求和保存文件操作
for title in titles {
    group.enter()

    let urlStr = "https://colors.limboy.me/colors/s/\(title)?_data=routes%2Fcolors.s.%24series"
    guard let url = URL(string: urlStr) else {
        fail("Invalid color URL: \(urlStr)")
    }

    let task = session.dataTask(with: url) { data, response, error in
        defer { group.leave() }

        if let error = error {
            fail("Color request failed for \(title): \(error)")
        }
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            fail("Color request failed for \(title): \(String(describing: response))")
        }
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let colors = json["colors"] as? [[String: Any]], !colors.isEmpty else {
            fail("Invalid colors JSON for \(title)")
        }
        do {
            // 获取Document目录路径
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            // 构建文件路径
            let filePath = documentsPath.appendingPathComponent("\(title).json")

            // 将响应数据保存为文件
            try data.write(to: filePath, options: .atomic)
            print("File saved for color \(title) at \(filePath)")
        } catch {
            fail("Error writing file for color \(title): \(error)")
        }
    }
    task.resume()
}

// 等待所有请求完成
group.wait()
