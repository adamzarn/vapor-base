import Vapor
import Fluent
import FluentPostgresDriver
import Mailgun
import Leaf
import SotoS3

/// Called before your application initializes.
public func configure(_ app: Application) throws {
    
    // AWS
    app.aws.client = AWSClient(httpClientProvider: .shared(app.http.client.shared))
    
    // Leaf
    app.views.use(.leaf)

    // Mailgun
    app.mailgun.configuration = .init(apiKey: Environment.mailgunApiKey)
    app.mailgun.defaultDomain = .defaultDomain
    
    // CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin, .accessControlAllowHeaders, .accessControlAllowCredentials, HTTPHeaders.Name("deviceId")]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors)

    // Serves files from `Public/` directory
    app.routes.defaultMaxBodySize = ByteCount(integerLiteral: Settings.maxBodySizeInBytes)
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Catches errors and converts to HTTP response
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    
    // Connect to Database
    app.databases.use(.postgres(configuration: app.environment.db.configuration), as: .psql)

    // Configure migrations
    app.migrations.add(CreateUsers(), to: .psql)
    app.migrations.add(CreateTokens(), to: .psql)
    app.migrations.add(CreateFollowingFollowers(), to: .psql)
    app.migrations.add(CreatePosts(), to: .psql)
    
    try app.autoMigrate().wait()
    
    try routes(app)
        
}
