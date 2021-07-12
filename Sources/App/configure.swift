import Vapor
import Fluent
import FluentPostgresDriver
import Mailgun
import Leaf

/// Called before your application initializes.
public func configure(_ app: Application) throws {
    
    // Leaf
    app.views.use(.leaf)

    // Mailgun
    app.mailgun.configuration = .init(apiKey: Environment.mailgunApiKey)
    app.mailgun.defaultDomain = .defaultDomain
    
    // CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin, .accessControlAllowHeaders, .accessControlAllowCredentials]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors)

    // Serves files from `Public/` directory
    app.routes.defaultMaxBodySize = ByteCount(integerLiteral: Settings.maxBodySizeInBytes)
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Catches errors and converts to HTTP response
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    
    // Connect to Database
    app.databases.use(try .postgres(url: DB.url(for: app.environment)), as: .psql)

    // Configure migrations
    app.migrations.add(CreateUsers(), to: .psql)
    app.migrations.add(CreateTokens(), to: .psql)
    app.migrations.add(CreateFollowingFollowers(), to: .psql)
    app.migrations.add(CreatePosts(), to: .psql)
    
    try app.autoMigrate().wait()
    
    try routes(app)
        
}
