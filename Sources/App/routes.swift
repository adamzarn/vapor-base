import Vapor

/// Register your application's routes here.
public func routes(_ app: Application) throws {
    
    app.get() { req in
        return "Welcome!"
    }

    try app.register(collection: UsersController())
    
}
