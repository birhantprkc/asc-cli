@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKProductVersionRepository: ProductVersionRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listInAppPurchaseVersions(iapId: String) async throws -> [Domain.ProductVersion] {
        let pages = try await client.requestAllPages(
            APIEndpoint.v2.inAppPurchases.id(iapId).versions.get(parameters: .init(limit: 200)),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        return pages.flatMap(\.data).map {
            map(id: $0.id, productId: iapId, kind: .inAppPurchase,
                version: $0.attributes?.version, state: $0.attributes?.state?.rawValue)
        }
    }

    public func listSubscriptionVersions(subscriptionId: String) async throws -> [Domain.ProductVersion] {
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.subscriptions.id(subscriptionId).versions.get(parameters: .init(limit: 200)),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        return pages.flatMap(\.data).map {
            map(id: $0.id, productId: subscriptionId, kind: .subscription,
                version: $0.attributes?.version, state: $0.attributes?.state?.rawValue)
        }
    }

    public func listSubscriptionGroupVersions(groupId: String) async throws -> [Domain.ProductVersion] {
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.subscriptionGroups.id(groupId).versions.get(parameters: .init(limit: 200)),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        return pages.flatMap(\.data).map {
            map(id: $0.id, productId: groupId, kind: .subscriptionGroup,
                version: $0.attributes?.version, state: $0.attributes?.state?.rawValue)
        }
    }

    /// The three SDK version types share the same attributes and state values.
    private func map(
        id: String, productId: String, kind: Domain.ProductVersionKind, version: Int?, state: String?
    ) -> Domain.ProductVersion {
        Domain.ProductVersion(
            id: id, productId: productId, kind: kind, version: version,
            state: state.flatMap(Domain.ProductVersionState.init(rawValue:)) ?? .prepareForSubmission
        )
    }
}
