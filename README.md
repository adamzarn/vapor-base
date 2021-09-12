# vapor-base 

[![codecov.io](https://codecov.io/github/adamzarn/vapor-base/coverage.svg?branch=master)](https://codecov.io/github/adamzarn/vapor-base?branch=master)

**vapor-base** is a backend template for a simple social media web application built with the Swift web framework [Vapor](https://github.com/vapor/vapor). It can serve as a starting point for any Swift developer who's looking to develop an API using Vapor, but who would prefer to learn by example. Some of the funcionality that's demonstrated in **vapor-base** includes:

* User Management with [Session Based Authentication](https://sherryhsu.medium.com/session-vs-token-based-authentication-11a6c5ac45e4)
* Querying data in a Postgresql Database using [Fluent](https://docs.vapor.codes/4.0/fluent/overview/)
* Sending emails using [Mailgun](https://www.mailgun.com/)
* Creating email templates using [Leaf](https://github.com/vapor/leaf)
* Storing photos using [AWS S3](https://aws.amazon.com/pm/serv-s3)

There is a companion frontend project [**vue-base**](https://github.com/adamzarn/vue-base), built with [Vue.js](https://github.com/vuejs/vue). It consumes the **vapor-base** API and is a great tool to quickly understand everything that **vapor-base** does, and it should also help you to visualize how you could build on top of it.

## Table of Contents  
* [Setup](#setup)  
  * [PostgreSQL](#postgresql)
    * [Create Development Server](#create-development-server)
    * [Create Development Database](#create-development-database)    
    * [Create Test Server](#create-test-server)
    * [Create Test Database](#create-test-database)
  * [Postico](#postico)
  * [Mailgun](#mailgun)
    * [.env](#env)
    * [Sandbox Domain](#sandbox-domain)
    * [Custom Domain](#custom-domain) 
  * [Run](#run)


* [Reference](#reference)
  * [Endpoints](#endpoints) 
    * [Auth](#auth)
    * [Users](#users)    
    * [Posts](#posts)
    * [Settings](#settings)

<a name="setup"/>

## Setup

<a name="postgresql"/>

### PostgreSQL

I would recommend downloading the latest version of [Postgres.app](https://postgresapp.com/downloads.html). Downloading the app automatically installs PostgreSQL, as well as PostGIS, and plv8, and it also provides a nice GUI.

<a name="create-development-server"/>

#### Create Development Server

When you open **Postgres.app** for the first time, you should see something like this:

<img width="773" alt="Screen Shot 2021-07-11 at 2 23 49 PM" src="https://user-images.githubusercontent.com/18072470/125207752-9e3ea280-e253-11eb-80b8-ec550bf3cb10.png">

Before you hit **Initialize** on the default server, let's actually create a new server by clicking the plus sign in the bottom left corner. Change the name to **Development**, change the Data Directory folder from **var-xx** to **development**, and select **Create Server**.

<img width="851" alt="Screen Shot 2021-07-11 at 2 50 41 PM" src="https://user-images.githubusercontent.com/18072470/125208355-6174aa80-e257-11eb-8803-f2fd6decbc60.png">

Delete the original server and then select **Start** (or **Initialize**) on the **Development** server.

<img width="851" alt="Screen Shot 2021-07-11 at 2 52 51 PM" src="https://user-images.githubusercontent.com/18072470/125208394-aac4fa00-e257-11eb-8db2-8186061114cf.png">

<a name="create-development-database"/>

#### Create vapor_base Development Database

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

<a name="create-test-server"/>

#### Create Test Server

While we're at it, let's create a test server for unit testing purposes by clicking the plus sign in the bottom left corner again. This time change the name to **Test**, change the Data Directory folder from **var-xx** to **test**, change the port to **5433**, and select **Create Server**.

<img width="851" alt="Screen Shot 2021-07-11 at 2 57 10 PM" src="https://user-images.githubusercontent.com/18072470/125208476-46ef0100-e258-11eb-82a1-2cb0c6013ff8.png">

Now select **Initialize** on the **Test** server.

<img width="851" alt="Screen Shot 2021-07-11 at 2 59 47 PM" src="https://user-images.githubusercontent.com/18072470/125208529-a9480180-e258-11eb-9176-b92c5e875ff7.png">

<a name="create-test-database"/>

#### Create vapor_base Test Database

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

<a name="postico"/>

### Postico

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

<a name="mailgun"/>

### Mailgun

<a name="env"/>

#### .env

Before creating a **mailgun** account, create a `.env` file and place it in the root of the **vapor-base** project. This is where you should store any personal or secret keys, including all of the information related to **mailgun**. Here are the keys you should add right now (you can fill in the values once you know them):

```bash
MAILGUN_API_KEY=
MAILGUN_SANDBOX_DOMAIN=
MAILGUN_DEFAULT_DOMAIN=
MAILGUN_FROM=
```

Now create a [**mailgun**](https://www.mailgun.com/) account.

Once you create your account and verify your email, you should be able to fill in the `MAILGUN_API_KEY` and the `MAILGUN_SANDBOX_DOMAIN`.

You can access the API Key from **Settings** -> **API Keys** -> **Private API key**, and the sandbox sending domain is in the **Dashboard** and should have this format: **sandbox{uuid}.mailgun.org**

<a name="sandbox-domain"/>

#### Sandbox Domain

If you want to be able to test with the sandbox domain, select it and add an email you have access to in the **Authorized Recipients** list:

<img width="1181" alt="Screen Shot 2021-07-12 at 4 01 05 PM" src="https://user-images.githubusercontent.com/18072470/125355438-ac132700-e32a-11eb-8f45-13d81798f034.png">

<a name="custom-domain"/>

#### Custom Domain

To add a custom domain, go to the **Sending** -> **Add New Domain**. Follow the instructions on how to format the domain name (be sure to use a domain that you actually own 😂) and use it as the value for `MAILGUN_DEFAULT_DOMAIN`.

Once you do that you'll need to select your new domain from the **Dashboard**, select **DNS records**, and add those records wherever you manage your domain. You should be adding 2 `TXT` records, 2 `MX` records, and 1 `CNAME` record. I personally use HostGator as my hosting provider, and to update this, I logged into HostGator's **cPanel**, went to **Domains** -> **Zone Editor**. Then I selected **Manage** on the domain, and from there I could add the `TXT`, `MX`, and `CNAME` records.

In `configure.swift`, you can select which domain to use with this line:

```swift
/// To use the sandbox domain
app.mailgun.defaultDomain = .sandboxDomain
/// To use your custom domain
app.mailgun.defaultDomain = .defaultDomain
```

Finally, fill in `MAILGUN_FROM` with what you want the from line of the emails to be. My custom domain is `zarndev.com`, so I set this value to `Adam Zarn <adam@zarndev.com>`. This can literally be anything, but if you want someone to be able to reply, it should be formatted correctly as an actual email address.

<a name="run"/>

### Run

After you've cloned the template, open the project in Xcode by double clicking the **Package.swift** file. Once you open the project, the Swift package dependency fetch will start automatically, and when it's finished the **vapor-base** scheme should appear next to the Build/Run and Stop buttons. Press the play button and your API will be running at <a>http://localhost:8080</a>!

<a name="reference"/>

## Reference

<a name="endpoints"/>

### Endpoints

<a name="auth"/>

#### Auth
| Name                          | Method      | Path                              | Authorization | Body    | Response        |
| ----------------------------- | ----------- | --------------------------------- | ------------- | ------- | --------------- |
| Register                      | **POST**    | /auth/register                    | No Auth       | User    | Token and User  |
| Login                         | **POST**    | /auth/login                       | Basic Auth    | No Body | Token and User  |
| Logout                        | **DELETE**  | /auth/logout                      | Bearer Token  | No Body | No Response     |
| Send Email Verification Email | **POST**    | /auth/sendEmailVerificationEmail  | No Auth       | No Body | No Response     |
| Verify Email                  | **PUT**     | /auth/verifyEmail/:tokenId        | No Auth       | No Body | No Response     |
| Send Password Reset Email     | **POST**    | /auth/sendPasswordResetEmail      | No Auth       | No Body | No Response     |
| Reset Password                | **PUT**     | /auth/resetPassword/:tokenId      | No Auth       | No Body | No Response     |

<a name="users"/>

#### Users
| Name                  | Method      | Path                      | Authorization | Body        | Response    |
| --------------------- | ----------- | ------------------------- | ------------- | ----------- | ----------- |
| Get User              | **GET**     | /users/:userId            | Bearer Token  | No Body     | User        |
| Get User Status       | **GET**     | /users/status?email=email | No Auth       | No Body     | User Status |
| Search Users          | **GET**     | /users/search?query=query | Bearer Token  | No Body     | [User]      |
| Follow                | **POST**    | /users/:userId/follow     | Bearer Token  | No Body     | No Response |
| Unfollow              | **DELETE**  | /users/:userId/unfollow   | Bearer Token  | No Body     | No Response |
| Get Followers         | **GET**     | /users/:userId/followers  | Bearer Token  | No Body     | [User]      |
| Get Following         | **GET**     | /users/:userId/following  | Bearer Token  | No Body     | [User]      |
| Get Follow Status         | **GET**     | /users/:userId/followStatus  | Bearer Token  | No Body     | FollowStatus      |
| Delete User           | **DELETE**  | /users/:userId            | Bearer Token  | No Body     | No Response |
| Update User           | **PUT**     | /users/:userId            | Bearer Token  | User Update | User        |
| Upload Profile Photo  | **POST**    | /users/profilePhoto       | Bearer Token  | File        | No Response |
| Delete Profile Photo  | **DELETE**  | /users/profilePhoto       | Bearer Token  | No Body     | No Response |

<a name="posts"/>

#### Posts
| Name        | Method   | Path           | Authorization | Body    | Response    |
| ----------- | ---------| -------------- | ------------- | ------- | ----------- |
| Create Post | **POST** | /posts         | Bearer Token  | Post    | No Response |
| Get Posts   | **GET**  | /posts/:userId | Bearer Token  | No Body | [Post]      |
| Get Feed    | **GET**  | /posts/feed    | Bearer Token  | No Body | [Post]      |

<a name="settings"/>

#### Settings
| Name         | Method  | Path      | Authorization | Body    | Response |
| ------------ | ------- | --------- | ------------- | ------- | -------- |
| Get Settings | **GET** | /settings | Bearer Token  | No Body | Settings |
