import Vapor
import Fluent
import FluentPostgresDriver
import Mailgun
import Leaf

/// Called before your application initializes.
public func configure(_ app: Application) throws {
    
    if !app.environment.isRelease {
        LeafRenderer.Option.caching = .bypass
    }
    app.views.use(.leaf)

    app.mailgun.configuration = .init(apiKey: APIKeys.mailgun)
    app.mailgun.defaultDomain = .defaultDomain
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin, .accessControlAllowHeaders, .accessControlAllowCredentials]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    
    app.middleware.use(cors)

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
