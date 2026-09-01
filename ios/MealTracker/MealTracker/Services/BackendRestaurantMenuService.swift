import Foundation

struct BackendRestaurantMenuService: RestaurantMenuSearching {
    private let baseURL: URL

    init?(bundle: Bundle = .main) {
        guard let value = bundle.object(forInfoDictionaryKey: "MEALTRACKER_API_BASE_URL") as? String,
              !value.isEmpty,
              !value.contains("$("),
              let baseURL = URL(string: value),
              baseURL.scheme == "https" else {
            return nil
        }
        self.baseURL = baseURL
    }

    func menu(for venue: VenueCandidate) async throws -> RestaurantMenuResult {
        guard let accessToken = BackendCredentialStore.accessToken else {
            throw MealAnalysisError.unavailable
        }

        var request = URLRequest(url: baseURL.appending(path: "api/restaurant-menu"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        // A free Render instance can spend roughly 50 seconds waking, and an
        // official-site web search can take another minute on a large menu.
        request.timeoutInterval = 150
        request.httpBody = try JSONEncoder().encode(
            BackendRestaurantMenuRequest(
                name: venue.name,
                subtitle: venue.subtitle,
                latitude: venue.latitude,
                longitude: venue.longitude
            )
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw MealAnalysisError.timedOut
        }
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw MealAnalysisError.unavailable
        }

        let result = try JSONDecoder().decode(BackendRestaurantMenuResponse.self, from: data)
        guard result.found,
              !result.items.isEmpty,
              let sourceURL = URL(string: result.sourceURL),
              sourceURL.scheme == "https" else {
            return .noReliableMenu
        }

        let source = RestaurantMenuSource(
            title: result.sourceTitle,
            url: sourceURL,
            retrievedAt: result.retrievedAt
        )
        let sourceHost = sourceURL.host() ?? result.sourceTitle
        let items = result.items.enumerated().map { index, item in
            let nutritionIsOfficial = item.nutritionSource == "official"
            return RestaurantMenuItem(
                id: "menu-\(index)",
                name: item.name,
                description: item.description,
                nutrition: NutritionFacts(
                    calories: item.calories,
                    protein: item.protein,
                    fat: item.fat,
                    carbohydrates: item.carbohydrates
                ),
                sourceDescription: nutritionIsOfficial
                    ? "Official nutrition from \(sourceHost)."
                    : "Official menu item from \(sourceHost); nutrition is an AI estimate.",
                isOfficial: nutritionIsOfficial
            )
        }
        return .available(items: items, source: source)
    }
}

private struct BackendRestaurantMenuRequest: Encodable {
    var name: String
    var subtitle: String
    var latitude: Double
    var longitude: Double
}

private struct BackendRestaurantMenuResponse: Decodable {
    var found: Bool
    var venueName: String
    var sourceTitle: String
    var sourceURL: String
    var retrievedAt: String
    var items: [BackendRestaurantMenuItem]
}

private struct BackendRestaurantMenuItem: Decodable {
    var name: String
    var description: String
    var calories: Double
    var protein: Double
    var fat: Double
    var carbohydrates: Double
    var nutritionSource: String
}
