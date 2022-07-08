# Jonline

*Note: though you can [build](https://github.com/JonLatane/jonline/tree/main/backend#building-and-running-locally) and [deploy](https://github.com/JonLatane/jonline/tree/main/backend#deploying) the skeleton service documented here, Jonline is nowhere near fully implemented as documented here.*

Jonline is an open-source server+client for maintaining a small, localized social network. A core goal is to make Jonline dogshit easy (🐕💩EZ) for anyone else to deploy to any Kubernetes provider of their choosing (and to fork and modify). It's also (optimistically) simple and straightforward enough to serve as a starter for many projects, so long as they retain the [GPLv3 license Jonline is released under](https://github.com/JonLatane/jonline/blob/main/LICENSE.md).

All you need is a Kubernetes (k8s) cluster with the names `jonline` and `jonline-postgres` available to have your own backend up in minutes. Assuming `kubectl` works, you can just `make create_db_deployment && make create_deployment` and you should have the backend up and running! Optionally, Jonline will also integrate with an external PostgreSQL DB (so you can skip the `make create_db_deployment`).

Why this goal for this project? See [Scaling Social Software via Federation](#scaling-social-software-via-federation).

## Motivations
Current social media and messaging solutions all kind of suck. In many ways, and in spite of his character issues, Richard Stallman was generally right about many of the problems social computing presents today. If we trust applications with closed source run on private Alphabet, Meta, Apple, etc. servers, *of course we're going to get the disinformation and effective-advertising-driven consumerism that plague the world today*. But of course, these models are great for building a profitable company that can return value to shareholders.

At the same time as the closed source/private server model has grown due to its profitability, software complexity has grown immensely, but largely unnecessarily, to handle scaling modern applications. MapReduce across a huge privately-owned cluster is absolutely useful for making the entire Internet searchable. But for communicating with a network of friends you know in real life, I don't really think it's necessary. Jonline is an attempt to prove this.

## Scaling Social Software via Federation
Jonline is a federated social network. The general idea is that it should provide a functional network with a single server, but that you should be able to communicate with users on other servers from a single account. This is handled via sharing of OAuth2 auth tokens between servers.

### Single-server usage
The intended use case for Jonline is thus:

I (Jon 😊👋) will run the Jonline server at https://jonline.io. It's fully open to the web and I'm paying for the DB behind it and the k8s cluster on it. Friends who want to connect with me can register for an account and communicate with me and with each other.

#### Posts
To keep things straightforward, all Posts in Jonline have global visibility. Twitter is easily the closest comparison.

#### Messages
Messages are understood to be private between individuals and not visible to other users. Private messaging is, of course, where the federated approach to Jonline does have some limitations.

##### Caveats
Crucially, with this model, *all my friends have to trust that I won't abuse being able to read their communications with each other*. A top priority after initial development of Jonline is to add an optional E2E encryption layer.

Why is E2E not the first priority? First, we must implement our client. To have E2E, we need a client to store decryption keys. And generally, the user must be responsible for storing their encryption keys themselves.

Once a client is implemented, it should be fairly straightforward to add E2E to the Messages feature in Jonline. But at the same time, it could be that this isn't something that needs solving, say, if support for linking into SMS/iMessage/WhatsApp is really a better solution for P2P messaging.

### Multi-server usage
Suppose you have two accounts with friends, say, on `jonline.io` and `bobline.com`. To federate your accounts, you may simply pass an `auth_token` from your `bobline.com` account that you use to talk to Bob (who I don't know) into `jonline.io`. The general idea is that users can choose to keep their primary account with the person they trust the most. Maybe it's not me 😭 But that's fine; I won't even know!
