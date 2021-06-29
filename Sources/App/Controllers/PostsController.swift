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
        tokenProtectedPostsRoute.get(use: getMyPosts)
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
    
    func getMyPosts(req: Request) throws -> EventLoopFuture<[Post.Public]> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = loggedInUser.id else {
                return req.fail(Exception.missingUserId)
            }
            let (start, end) = req.searchRange
            return Post.query(on: req.db)
                .filter(\.$user.$id == userId)
                .range(start..<end)
                .all()
                .flatMapThrowing { posts in
                    return try posts.compactMap { try $0.asPublic() }
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
