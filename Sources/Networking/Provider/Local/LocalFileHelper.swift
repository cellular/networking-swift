import Foundation

internal class LocalFileHelper {

    class func createMapping(with definition: LocalFileDefinition) throws -> LocalFileMapContainer {

        var fileName = definition.fileName
        if fileName.contains(".json") {
            fileName = fileName.replacingOccurrences(of: ".json", with: "")
        }

        /// load definition file
        if let jsonDefinitionFilePath = definition.bundle.path(forResource: fileName, ofType: "json") {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonDefinitionFilePath), options: .alwaysMapped)

            /// parse json from definition file
            let decoder = JSONDecoder()
            let mapContainer = try decoder.decode(LocalFileMapContainer.self, from: jsonData)

            /// replace palceholders with provided replacements
            var replacedMaps = [LocalFileMap]()
            for map in mapContainer.maps {
                var mapFileName = map.fileName
                let fileType = map.fileType ?? "json"
                if mapFileName.contains(".\(fileType)") {
                    mapFileName = mapFileName.replacingOccurrences(of: ".\(fileType)", with: "")
                }
                var replacedUrl = map.url
                for key in definition.placeholders.keys {
                    if replacedUrl.contains(key), let replacementString = definition.placeholders[key] {
                        replacedUrl = replacedUrl.replacingOccurrences(of: key, with: replacementString)
                    }
                }
                let replacedMap = LocalFileMap(url: replacedUrl,
                                               fileName: mapFileName, fileType: map.fileType, statusCode: map.statusCode)
                replacedMaps.append(replacedMap)
            }

            return LocalFileMapContainer(maps: replacedMaps)
        }
        throw Error.serializationFailed("Could not parse \(fileName).json")
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
