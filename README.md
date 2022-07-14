# Jonline

*Note: though you can [build](https://github.com/JonLatane/jonline/tree/main/backend#building-and-running-locally) and [deploy](https://github.com/JonLatane/jonline/tree/main/backend#deploying) the skeleton service documented here, Jonline is nowhere near fully implemented as documented here.*

Jonline is an open-source server+client for maintaining a small, localized social network. A core goal is to make Jonline dogshit easy (🐕💩EZ) for anyone else to deploy to any Kubernetes provider of their choosing (and to fork and modify). It's also (optimistically) simple and straightforward enough to serve as a starter for many projects, so long as they retain the [GPLv3 license Jonline is released under](https://github.com/JonLatane/jonline/blob/main/LICENSE.md).

All you need is a Kubernetes (k8s) cluster with the names `jonline` and `jonline-postgres` available to have your own backend up in minutes.  your `kubectl` works, simply `make create_db_deployment create_be_deployment` from the root if this repo, and you'll have a backend up and running from the [prebuilt images](https://hub.docker.com/repository/docker/jonlatane/jonline). Optionally, Jonline will also integrate with an external PostgreSQL DB (so you can skip the `create_db_deployment`).

Why this goal for this project? See [Scaling Social Software via Federation](#scaling-social-software-via-federation).

## Motivations
Current social media and messaging solutions all kind of suck. The early open source software (OSS) movement, dating to the 80s, was generally right about many of the problems that have arisen mixing a market(ing)-based economy with social computing. If we entrust our social interactions to applications with closed source run on private Alphabet, Meta, Apple, etc. servers, *of course we're going to see the disinformation and effective-advertising-driven consumerism that plague the world today*. These models are very profitable.

Meanwhile, email has existed for a *long time* even though it's not very profitable. Notably, email is a federated protocol. You can use any email provider to talk to anyone else on any other email provider. At any time, you can take all your message history to any other email provider. It's even easy to set up forwarding/notifying contacts of an address change *just because* the email protocol is so standardized. And while, yes, spam was a problem at one point, the consequences of social media meeting data-driven advertising have been demonstrably more problematic and harder to solve via legislation.

There isn't an open federated protocol like email for a complete posts+events+messaging package, even though this is essentially how most people use a large amount of their screen time. Lots of non-open, privatized implementations exist, like Facebook, Google+, and so forth. Other federated protocols like XMPP and CalDAV have replicated many of the communication features we use social media for, but are really meant for decades-old problems rather than what social media apps "solve." XMPP and CalDAV have seen varying degrees of success, but like many protocols more than a decade old, they're a bit obscure and hard to use; most devs only use "high-level" libraries to do this kind of work. Fortunately, in the last decade or so, Google has built and refined a free way to [create a protocol ourselves](https://grpc.io) that works in virtually any language and is straightforward enough for most developers.

So, Jonline is a shot at implementing federated, open social media, in a way that is easy for developers to modify and, perhaps most importantly, for *users to understand*.

### Features/Single-server usage
The intended use case for Jonline is thus:

I (Jon 😊👋) will run the Jonline server at https://jonline.io. It's fully open to the web and I'm paying for the DB behind it and the k8s cluster on it. Friends who want to connect with me can register for an account and communicate with me and with each other.

#### Posts
To keep things straightforward, all Posts in Jonline have global visibility. Twitter is easily the closest comparison.

#### Events
Events may be public, private, or private with friend invitations.

#### Messages
Messages are understood to be private between individuals and not visible to other users. Private messaging is, of course, where the federated approach to Jonline does have some limitations.

##### Caveats
Crucially, with this model, *all my friends have to trust that I won't abuse being able to read their communications with each other*. A top priority after initial development of Jonline is to add an optional E2E encryption layer.

Why is E2E not the first priority? First, we must implement our client. To have E2E, we need a client to store decryption keys. And generally, the user must be responsible for storing their encryption keys themselves.

Once a client is implemented, it should be fairly straightforward to add E2E to the Messages feature in Jonline. But at the same time, it could be that this isn't something that needs solving, say, if support for linking into SMS/iMessage/WhatsApp is really a better solution for P2P messaging.

### Multi-server usage
Suppose you have two accounts with friends, say, on `jonline.io` and `bobline.com`. To federate your accounts, you may simply pass an `auth_token` from your `bobline.com` account that you use to talk to Bob (who I don't know) into `jonline.io`. The general idea is that users can choose to keep their primary account with the person they trust the most. Maybe it's not me 😭 But that's fine; I won't even know!

## Technical stuff
You can create a Jonline account right now! I will probably delete it eventually though

```sh
grpc_cli call be.jonline.io:27707 CreateAccount 'username: "hi-you", password: "very-secure"'
```
### Scaling Social Software via Federation
At the same time as the closed source/private server model has grown due to its profitability, software complexity has grown immensely to handle scaling these "modern" applications. But is scaling social media applications in this way *necessary for what people use these applications for*? Or is it *the best way to keep data available for marketing and other private use*? Or more simply: are we optimizing for profit, or for actual computer performance? There are many legitimate applications for, say, MapReduce across a huge privately-owned cluster, like making the entire Internet searchable. But for communicating with a network of friends you know in real life, I don't really think it's necessary.

Jonline is a federated social network. The general idea is that it should provide a functional network with a single server, but that you should be able to communicate with users on other servers from a single account. This is handled via sharing of OAuth2 auth tokens between servers.

#### Technical underpinnings
The core of Jonline is a very generic, boring gRPC definition of OAuth2 [authentication](https://github.com/JonLatane/jonline/blob/main/protos/authentication.proto) with a small [federation](https://github.com/JonLatane/jonline/blob/main/protos/federation.proto) protocol atop it. Hopefully, most developers who have used OAuth2 should understand how Jonline works just by reading those two files (even those familiar with Protobuf/gRPC). If not (and really, especially if so) please make some PRs!
