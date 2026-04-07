import Foundation

// MARK: - Hexagonal Protocol

typealias HexagonalNext = (AppRequest, RequestContext) async -> AppResponse

protocol HexagonalLayer {
    func handle(
        request: AppRequest,
        context: RequestContext,
        next: @escaping HexagonalNext
    ) async -> AppResponse
}

// MARK: - Hexagonal Chain

final class HexagonalChain {
    private var layers: [HexagonalLayer] = []
    private let finalHandler: (AppRequest, RequestContext) async -> AppResponse
    
    init(finalHandler: @escaping (AppRequest, RequestContext) async -> AppResponse) {
        self.finalHandler = finalHandler
    }
    
    func use(_ layer: HexagonalLayer) {
        layers.append(layer)
    }
    
    func execute(request: AppRequest, context: RequestContext) async -> AppResponse {
        await executeChain(at: 0, request: request, context: context)
    }
    
    private func executeChain(
        at index: Int,
        request: AppRequest,
        context: RequestContext
    ) async -> AppResponse {
        if index >= layers.count {
            return await finalHandler(request, context)
        }
        
        let layer = layers[index]
        
        let next: HexagonalNext = { [weak self] req, ctx in
            guard let self = self else {
                return .error(HexagonalError.invalidData)
            }
            return await self.executeChain(at: index + 1, request: req, context: ctx)
        }
        
        return await layer.handle(request: request, context: context, next: next)
    }
}
