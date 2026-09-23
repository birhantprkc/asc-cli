@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKBundleIDRepository: BundleIDRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listBundleIDs(platform: Domain.BundleIDPlatform?, identifier: String?) async throws -> [Domain.BundleID] {
        let filterPlatform = platform.flatMap {
            APIEndpoint.V1.BundleIDs.GetParameters.FilterPlatform(rawValue: $0.rawValue)
        }
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.bundleIDs.get(parameters: .init(
                filterPlatform: filterPlatform.map { [$0] },
                filterIdentifier: identifier.map { [$0] },
                limit: 200
            )),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        return pages.flatMap(\.data).map(mapBundleID)
    }

    public func createBundleID(name: String, identifier: String, platform: Domain.BundleIDPlatform) async throws -> Domain.BundleID {
        guard let sdkPlatform = AppStoreConnect_Swift_SDK.BundleIDPlatform(rawValue: platform.rawValue) else {
            throw APIError.unknown("Unsupported platform: \(platform.rawValue)")
        }
        let body = BundleIDCreateRequest(data: .init(
            type: .bundleIDs,
            attributes: .init(name: name, platform: sdkPlatform, identifier: identifier)
        ))
        let response = try await client.request(APIEndpoint.v1.bundleIDs.post(body))
        return mapBundleID(response.data)
    }

    public func deleteBundleID(id: String) async throws {
        try await client.request(APIEndpoint.v1.bundleIDs.id(id).delete)
    }

    // MARK: - Mapper

    private func mapBundleID(_ sdkBundleID: AppStoreConnect_Swift_SDK.BundleID) -> Domain.BundleID {
        let platform = sdkBundleID.attributes?.platform.flatMap {
            Domain.BundleIDPlatform(rawValue: $0.rawValue)
        } ?? .universal
        return Domain.BundleID(
            id: sdkBundleID.id,
            name: sdkBundleID.attributes?.name ?? "",
            identifier: sdkBundleID.attributes?.identifier ?? "",
            platform: platform,
            seedID: sdkBundleID.attributes?.seedID
        )
    }
}
