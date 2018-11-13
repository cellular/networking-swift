import Foundation

internal class LocalFileHelper {

    class func createMapping(with definition: LocalFileDefinition) throws -> LocalFileMapContainer {

        var fileName = definition.fileName
        if let jsonEnding = fileName.range(of: ".json") {
            fileName.removeSubrange(jsonEnding)
        }

        /// load definition file
        guard let jsonDefinitionFilePath = definition.bundle.path(forResource: fileName, ofType: "json") else {
            throw Error.serializationFailed("Could not parse \(fileName).json")
        }
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonDefinitionFilePath), options: .alwaysMapped)

        /// parse json from definition file
        let decoder = JSONDecoder()
        let container = try decoder.decode(LocalFileMapContainer.self, from: jsonData)

        /// replace palceholders with provided replacements
        let replacedMaps: [LocalFileMap] = container.fileMaps.map { fileMap in
            var fileMapName = fileMap.fileName
            let fileType = fileMap.fileType ?? "json"
            if let fileEnding = fileMapName.range(of: ".\(fileType)") {
                fileMapName.removeSubrange(fileEnding)
            }

            // Replaces each key with corresponding value on fileMap.url
            let url = definition.placeholders.keys.reduce(fileMap.url, { partialResult, key in
                guard let replacement = definition.placeholders[key] else { return partialResult }
                return partialResult.replacingOccurrences(of: key, with: replacement)
            })
            return LocalFileMap(url: url, fileName: fileMapName, fileType: fileType, statusCode: fileMap.statusCode)
        }

        return LocalFileMapContainer(fileMaps: replacedMaps)
    }

    class func findWildcard(for url: URL, in maps: [LocalFileMap]) -> LocalFileMap? {
        let possibleWildcards = maps.filter({ $0.url.last == "*" })
        let urlReducedByLastPath = url.deletingLastPathComponent()
        guard let urlReducedByLastPathWithAsterisk = URL(string: "\(urlReducedByLastPath.absoluteString)*"),
        urlReducedByLastPath.absoluteString != url.absoluteString,
        !urlReducedByLastPath.absoluteString.contains("..") else { return nil }
        if let map = possibleWildcards.first(where: { $0.url == urlReducedByLastPathWithAsterisk.absoluteString}) {
            return map
        } else {
            return LocalFileHelper.findWildcard(for: urlReducedByLastPath, in: maps)
        }
    }

}
