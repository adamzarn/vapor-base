import Vapor
import Leaf

/// Register your application's routes here.
public func routes(_ app: Application) throws {

    try app.register(collection: AuthController())
    try app.register(collection: UsersController())
    try app.register(collection: SettingsController())
    try app.register(collection: ViewController())
    
}
