import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(EXIT_FAILURE)
}

// 创建一个DispatchGroup以便等待所有请求完成
let group = DispatchGroup()

// 创建一个URLSession对象
let session = URLSession.shared

// 循环遍历月份，进行异步网络请求和保存文件操作
for month in 1...12 {
    group.enter()

    let urlStr = "https://colors.limboy.me/colors/d/\(month)?_data=routes%2Fcolors.d.$month"
    guard let url = URL(string: urlStr) else {
        fail("Invalid month URL: \(urlStr)")
    }

    let task = session.dataTask(with: url) { data, response, error in
        defer { group.leave() }

        if let error = error {
            fail("Month request failed for \(month): \(error)")
        }
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            fail("Month request failed for \(month): \(String(describing: response))")
        }
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let colors = json["colors"] as? [[String: Any]], !colors.isEmpty else {
            fail("Invalid colors JSON for month \(month)")
        }
        do {
            // 获取Document目录路径
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            // 构建文件路径
            let filePath = documentsPath.appendingPathComponent("\(month).json")

            // 将响应数据保存为文件
            try data.write(to: filePath, options: .atomic)
            print("File saved for month \(month) at \(filePath)")
        } catch {
            fail("Error writing file for month \(month): \(error)")
        }
    }
    task.resume()
}

// 等待所有请求完成
group.wait()
