@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKProfileRepository: ProfileRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listProfiles(bundleIdId: String?, profileType: Domain.ProfileType?) async throws -> [Domain.Profile] {
        if let bundleIdId {
            // Use the bundle ID relationship endpoint for server-side filtering
            let pages = try await client.requestAllPages(
                APIEndpoint.v1.bundleIDs.id(bundleIdId).profiles.get(limit: 200),
                nextCursor: { $0.meta?.paging.nextCursor }
            )
            return pages.flatMap(\.data).map { mapProfile($0, bundleIdId: bundleIdId) }
        } else {
            let filterType = profileType.flatMap {
                APIEndpoint.V1.Profiles.GetParameters.FilterProfileType(rawValue: $0.rawValue)
            }
            let pages = try await client.requestAllPages(
                APIEndpoint.v1.profiles.get(parameters: .init(
                    filterProfileType: filterType.map { [$0] },
                    limit: 200
                )),
                nextCursor: { $0.meta?.paging.nextCursor }
            )
            return pages.flatMap(\.data).map { sdkProfile in
                let parentId = sdkProfile.relationships?.bundleID?.data?.id ?? ""
                return mapProfile(sdkProfile, bundleIdId: parentId)
            }
        }
    }

    public func createProfile(
        name: String,
        profileType: Domain.ProfileType,
        bundleIdId: String,
        certificateIds: [String],
        deviceIds: [String]
    ) async throws -> Domain.Profile {
        guard let sdkProfileType = ProfileCreateRequest.Data.Attributes.ProfileType(rawValue: profileType.rawValue) else {
            throw APIError.unknown("Unsupported profile type: \(profileType.rawValue)")
        }
        let devices: ProfileCreateRequest.Data.Relationships.Devices? = deviceIds.isEmpty ? nil : .init(
            data: deviceIds.map { .init(type: .devices, id: $0) }
        )
        let body = ProfileCreateRequest(data: .init(
            type: .profiles,
            attributes: .init(name: name, profileType: sdkProfileType),
            relationships: .init(
                bundleID: .init(data: .init(type: .bundleIDs, id: bundleIdId)),
                devices: devices,
                certificates: .init(data: certificateIds.map { .init(type: .certificates, id: $0) })
            )
        ))
        let response = try await client.request(APIEndpoint.v1.profiles.post(body))
        return mapProfile(response.data, bundleIdId: bundleIdId)
    }

    public func deleteProfile(id: String) async throws {
        try await client.request(APIEndpoint.v1.profiles.id(id).delete)
    }

    // MARK: - Mapper

    private func mapProfile(
        _ sdkProfile: AppStoreConnect_Swift_SDK.Profile,
        bundleIdId: String
    ) -> Domain.Profile {
        let profileType = sdkProfile.attributes?.profileType.flatMap {
            Domain.ProfileType(rawValue: $0.rawValue)
        } ?? .iosAppStore
        let profileState = sdkProfile.attributes?.profileState.flatMap {
            Domain.ProfileState(rawValue: $0.rawValue)
        } ?? .active
        return Domain.Profile(
            id: sdkProfile.id,
            name: sdkProfile.attributes?.name ?? "",
            profileType: profileType,
            profileState: profileState,
            bundleIdId: bundleIdId,
            expirationDate: sdkProfile.attributes?.expirationDate,
            uuid: sdkProfile.attributes?.uuid,
            profileContent: sdkProfile.attributes?.profileContent
        )
    }
}
