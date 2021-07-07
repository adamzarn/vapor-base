//
//  PostsController.swift
//  App
//
//  Created by Adam Zarn on 6/7/21.
//

import Foundation
import Vapor
import Fluent

class PostsController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let postsRoute = routes.grouped(Post.pathComponent)
        let tokenProtectedPostsRoute = postsRoute.grouped(UserBearerAuthenticator())
        
        tokenProtectedPostsRoute.post(use: createPost)
        tokenProtectedPostsRoute.get(use: getPosts)
        tokenProtectedPostsRoute.get(":userId", use: getPosts)
        tokenProtectedPostsRoute.get("feed", use: getFeed)

    }
    
    func createPost(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let postData = try? req.content.decode(NewPost.self),
                  postData.text.isEmpty == false else {
                return req.fail(Exception.invalidPost)
            }
            let post = try loggedInUser.createPost(from: postData)
            return post.save(on: req.db).transform(to: HTTPStatus.created)
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func getPosts(req: Request) throws -> EventLoopFuture<[Post.Public]> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = req.parameters.get("userId") ?? loggedInUser.id else {
                return req.fail(Exception.missingUserId)
            }
            let (start, end) = req.searchRange
            return User.find(userId, on: req.db).flatMap { user in
                guard let user = user else {
                    return req.fail(Exception.userDoesNotExist)
                }
                return user.$posts.query(on: req.db)
                    .with(\.$user)
                    .range(start..<end)
                    .sort(\.$createdAt, .descending)
                    .all().flatMapThrowing { posts in
                        return try posts.compactMap { try $0.asPublic() }
                    }
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func getFeed(req: Request) throws -> EventLoopFuture<[Post.Public]> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            return loggedInUser.$following.query(on: req.db).all().flatMap { users in
                var userIds = users.compactMap { $0.id }
                if let loggedInUserId = loggedInUser.id {
                    userIds.append(loggedInUserId)
                }
                let (start, end) = req.searchRange
                return Post.query(on: req.db)
                    .with(\.$user)
                    .filter(\.$user.$id ~~ userIds)
                    .range(start..<end)
                    .sort(\.$createdAt, .descending)
                    .all().flatMapThrowing { posts in
                        return try posts.compactMap { try $0.asPublic() }
                    }
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
}
