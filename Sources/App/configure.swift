import Vapor
import Fluent
import FluentPostgresDriver
import Mailgun
import Leaf

/// Called before your application initializes.
public func configure(_ app: Application) throws {
    
    app.views.use(.leaf)
    app.leaf.cache.isEnabled = app.environment.isRelease
    
    app.mailgun.configuration = .init(apiKey: APIKeys.mailgun)
    app.mailgun.defaultDomain = .defaultDomain

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory)) // Serves files from `Public/` directory
    app.middleware.use(ErrorMiddleware.default(environment: app.environment)) // Catches errors and converts to HTTP response

    // Connect to Database
    if let databaseURL = Environment.get("DATABASE_URL") {
        app.databases.use(try .postgres(url: databaseURL), as: .psql)
    } else {
        app.databases.use(try .postgres(url: DB.dev.url), as: .psql)
    }

    // Configure migrations
    app.migrations.add(CreateUsers(), to: .psql)
    app.migrations.add(CreateTokens(), to: .psql)
    app.migrations.add(CreateFollowingFollowers(), to: .psql)
    try app.autoMigrate().wait()
    
    try routes(app)
        
}
