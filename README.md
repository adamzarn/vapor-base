# vapor-base 

[![codecov.io](https://codecov.io/github/adamzarn/vapor-base/coverage.svg?branch=master)](https://codecov.io/github/adamzarn/vapor-base?branch=master)

**vapor-base** is a web application backend template built with the Swift web framework [Vapor](https://github.com/vapor/vapor). It can serve as a starting point for any Swift developer who's looking to develop an API using Vapor, but who would prefer to learn by example. Some of the funcionality that's demonstrated in **vapor-base** includes:

* User Management with [Session Based Authentication](https://sherryhsu.medium.com/session-vs-token-based-authentication-11a6c5ac45e4)
* Querying data in a Postgresql Database using [Fluent](https://docs.vapor.codes/4.0/fluent/overview/)
* Sending emails using [Mailgun](https://www.mailgun.com/)
* Creating email templates using [Leaf](https://github.com/vapor/leaf)

There is a companion frontend project [**vue-base**](https://github.com/adamzarn/vue-base), built with [Vue.js](https://github.com/vuejs/vue). It consumes the **vapor-base** API and is a great tool to quickly understand everything that **vapor-base** does, and it should also help you to visualize how you could build on top of it.

## Endpoints

### Auth
| Name                          | Method      | Path                              | Authorization | Body    | Response        |
| ----------------------------- | ----------- | --------------------------------- | ------------- | ------- | --------------- |
| Register                      | **POST**    | /auth/register                    | No Auth       | User    | Token and User  |
| Login                         | **POST**    | /auth/login                       | Basic Auth    | No Body | Token and User  |
| Logout                        | **DELETE**  | /auth/logout                      | Bearer Token  | No Body | No Response     |
| Send Email Verification Email | **POST**    | /auth/sendEmailVerificationEmail  | No Auth       | No Body | No Response     |
| Verify Email                  | **PUT**     | /auth/verifyEmail/:tokenId        | No Auth       | No Body | No Response     |
| Send Password Reset Email     | **POST**    | /auth/sendPasswordResetEmail      | No Auth       | No Body | No Response     |
| Reset Password                | **PUT**     | /auth/resetPassword/:tokenId      | No Auth       | No Body | No Response     |

### Users
| Name                  | Method      | Path                      | Authorization | Body        | Response    |
| --------------------- | ----------- | ------------------------- | ------------- | ----------- | ----------- |
| Get User              | **GET**     | /users/:userId            | Bearer Token  | No Body     | User        |
| Get User Status       | **GET**     | /users/status?email=email | No Auth       | No Body     | User Status |
| Search Users          | **GET**     | /users/search?query=query | Bearer Token  | No Body     | [User]      |
| Follow                | **POST**    | /users/:userId/follow     | Bearer Token  | No Body     | No Response |
| Unfollow              | **DELETE**  | /users/:userId/unfollow   | Bearer Token  | No Body     | No Response |
| Get Followers         | **GET**     | /users/:userId/followers  | Bearer Token  | No Body     | [User]      |
| Get Following         | **GET**     | /users/:userId/following  | Bearer Token  | No Body     | [User]      |
| Delete User           | **DELETE**  | /users/:userId            | Bearer Token  | No Body     | No Response |
| Update User           | **PUT**     | /users/:userId            | Bearer Token  | User Update | User        |
| Upload Profile Photo  | **POST**    | /users/profilePhoto       | Bearer Token  | File        | No Response |
| Delete Profile Photo  | **DELETE**  | /users/profilePhoto       | Bearer Token  | No Body     | No Response |

### Posts
| Name        | Method   | Path           | Authorization | Body    | Response    |
| ----------- | ---------| -------------- | ------------- | ------- | ----------- |
| Create Post | **POST** | /posts         | Bearer Token  | Post    | No Response |
| Get Posts   | **GET**  | /posts/:userId | Bearer Token  | No Body | [Post]      |
| Get Feed    | **GET**  | /posts/feed    | Bearer Token  | No Body | [Post]      |

### Settings
| Name         | Method  | Path      | Authorization | Body    | Response |
| ------------ | ------- | --------- | ------------- | ------- | -------- |
| Get Settings | **GET** | /settings | Bearer Token  | No Body | Settings |
