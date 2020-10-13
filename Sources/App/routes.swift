import Vapor
import Leaf

/// Register your application's routes here.
public func routes(_ app: Application) throws {

    app.get { req -> EventLoopFuture<View> in
        return req.view.render("index", Context(baseUrl: req.baseUrl))
    }

    try app.register(collection: UsersController())
    try app.register(collection: ViewController())
    
}
