# vapor-base 

[![codecov.io](https://codecov.io/github/adamzarn/vapor-base/coverage.svg?branch=master)](https://codecov.io/github/adamzarn/vapor-base?branch=master)

**vapor-base** is a backend template for a simple social media web application built with the Swift web framework [Vapor](https://github.com/vapor/vapor). It can serve as a starting point for any Swift developer who's looking to develop an API using Vapor, but who would prefer to learn by example. Some of the funcionality that's demonstrated in **vapor-base** includes:

* User Management with [Session Based Authentication](https://sherryhsu.medium.com/session-vs-token-based-authentication-11a6c5ac45e4)
* Querying data in a Postgresql Database using [Fluent](https://docs.vapor.codes/4.0/fluent/overview/)
* Sending emails using [Mailgun](https://www.mailgun.com/)
* Creating email templates using [Leaf](https://github.com/vapor/leaf)

There is a companion frontend project [**vue-base**](https://github.com/adamzarn/vue-base), built with [Vue.js](https://github.com/vuejs/vue). It consumes the **vapor-base** API and is a great tool to quickly understand everything that **vapor-base** does, and it should also help you to visualize how you could build on top of it.

## Setup

After you've cloned the template, there are a few things you need to do:

### Download Dependencies

All you have to do to download the Swift package dependencies is open the **Package.swift** file using Xcode. The packages will be fetched automatically, and when it's finished the **vapor-base** scheme should appear next to the Build/Run and Stop buttons.

### Install PostgreSQL

I would recommend downloading the latest version of [Postgres.app](https://postgresapp.com/downloads.html). Downloading the app automatically installs PostgreSQL, as well as PostGIS, and plv8, and it also provides a nice GUI.

### Create Development Server

When you open **Postgres.app** for the first time, you should see something like this:

<img width="773" alt="Screen Shot 2021-07-11 at 2 23 49 PM" src="https://user-images.githubusercontent.com/18072470/125207752-9e3ea280-e253-11eb-80b8-ec550bf3cb10.png">

Before you hit **Initialize** on the default server, let's actually create a new server by clicking the plus sign in the bottom left corner. Change the name to **Development**, change the Data Directory folder from **var-xx** to **development**, and select **Create Server**.

<img width="851" alt="Screen Shot 2021-07-11 at 2 50 41 PM" src="https://user-images.githubusercontent.com/18072470/125208355-6174aa80-e257-11eb-8803-f2fd6decbc60.png">

Delete the original server and then select **Start** (or **Initialize**) on the **Development** server.

<img width="851" alt="Screen Shot 2021-07-11 at 2 52 51 PM" src="https://user-images.githubusercontent.com/18072470/125208394-aac4fa00-e257-11eb-8db2-8186061114cf.png">

### Create vapor_base Development Database

Now your **Development** server should be running with 3 default databases:

<img width="773" alt="Screen Shot 2021-07-11 at 2 34 40 PM" src="https://user-images.githubusercontent.com/18072470/125207938-22ddf080-e255-11eb-8d1b-f95af7ae079a.png">

Double click on any of those 3 databases, and a terminal window will open like this:

<img width="697" alt="Screen Shot 2021-07-11 at 2 42 14 PM" src="https://user-images.githubusercontent.com/18072470/125208112-3c336c80-e256-11eb-8cad-c1c4f26d8b53.png">

Use the following command to create the **vapor-base** database:

```bash
CREATE DATABASE vapor_base;
```

Close out of the terminal window, and now you should see this:

<img width="851" alt="Screen Shot 2021-07-11 at 2 44 24 PM" src="https://user-images.githubusercontent.com/18072470/125208165-7e5cae00-e256-11eb-8871-0023d3752a84.png">

### Create Test Server

While we're at it, let's create a test server for unit testing purposes by clicking the plus sign in the bottom left corner again. This time change the name to **Test**, change the Data Directory folder from **var-xx** to **test**, change the port to **5433**, and select **Create Server**.

<img width="851" alt="Screen Shot 2021-07-11 at 2 57 10 PM" src="https://user-images.githubusercontent.com/18072470/125208476-46ef0100-e258-11eb-82a1-2cb0c6013ff8.png">

Now select **Initialize** on the **Test** server.

<img width="851" alt="Screen Shot 2021-07-11 at 2 59 47 PM" src="https://user-images.githubusercontent.com/18072470/125208529-a9480180-e258-11eb-9176-b92c5e875ff7.png">

### Create vapor_base Test Database

Now your **Test** server should be running with 3 default databases:

<img width="851" alt="Screen Shot 2021-07-11 at 3 01 55 PM" src="https://user-images.githubusercontent.com/18072470/125208576-f035f700-e258-11eb-9168-903f44134f8f.png">

Double click on any of those 3 databases, and a terminal window will open like this:

<img width="697" alt="Screen Shot 2021-07-11 at 3 04 42 PM" src="https://user-images.githubusercontent.com/18072470/125208650-6a667b80-e259-11eb-827d-a35dc1ccc0e9.png">

Use the following command to create the **vapor-base** database:

```bash
CREATE DATABASE vapor_base;
```

Close out of the terminal window, and now you should see this:

<img width="851" alt="Screen Shot 2021-07-11 at 3 02 43 PM" src="https://user-images.githubusercontent.com/18072470/125208590-0d6ac580-e259-11eb-853d-91e3a63ba95d.png">

Congratulations, you now have a Development server running on port 5432 and a Test server running on port 5433!

### Download Postico

Another app I highly recommend is [Postico](https://eggerapps.at/postico/). While **Postgres.app** is a GUI for PostgreSQL servers, **Postico** provides a GUI for the tables and rows of each individual database on your servers.

When you first open **Postico**, you'll be prompted to add a favorite database. Enter the information for the vapor_base development database like so:

<img width="762" alt="Screen Shot 2021-07-11 at 3 23 21 PM" src="https://user-images.githubusercontent.com/18072470/125209069-faa5c000-e25b-11eb-8228-7a2a21b2a662.png">

Add a new favorite by selecting **New Favorite** in the bottom left corner. Enter the information for the vapor_base test database like so:

<img width="762" alt="Screen Shot 2021-07-11 at 3 20 53 PM" src="https://user-images.githubusercontent.com/18072470/125209003-9682fc00-e25b-11eb-9c8f-337abf745293.png">

More congratulations are in order! Just select **Connect** and you'll be able to view the data stored in your Development and Test databases.

<img width="762" alt="Screen Shot 2021-07-11 at 3 27 19 PM" src="https://user-images.githubusercontent.com/18072470/125209145-7c95e900-e25c-11eb-8782-29c2c2dbd3ee.png">

**Note**: **vapor-base** connects to these databases via a url that is configured in `DB.swift`. Here are the urls for these two databases:

* Development: postgres://postgres:@localhost:5432/vapor_base
* Test: postgres://postgres:@localhost:5433/vapor_base

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
