# Example: `fastly-rails` on Cloud Foundry

This `todo` example has been modified to run on Cloud Foundry and use a Fastly service broker to manage credentials and access to the Fastly API. It is a proof of concept.

## Proof of Concept

This application proves the simplicity of deploying an application on Cloud Foundry and integrating it with Fastly's CDN using modern, microservices style techniques. Cloud Foundry offers the ability for services to register and be available via a "marketplace". This example will simulate that model using a "user provided service" to securely manage fastly API credentials and make them available to bound applications.

The key code-change to integrate brokered Fastly credentials with this rails app is [here](https://github.com/cwest/todo/commit/d4d15f421c6dd5d747bf57950accccf2b020c144).

## Deploying

Deploying this app to Cloud Foundry is simple. There are a couple things you need:

1. A Fastly account with an API key. Collect your API key from [your Fastly account page](https://app.fastly.com/#account).
2. A Cloud Foundry instance account. You can try [Pivotal Web Services](https://run.pivotal.io) free.
3. The [Cloud Foundry CLI](https://github.com/cloudfoundry/cli#downloads).
4. A domain you can manage DNS on. I will assume it's `caseywest.com`.

### Get the Code

```sh
$ git clone https://github.com/cwest/todo.git
$ cd todo
$ git checkout cloudfoundry-compat
```

### Log into Cloud Foundry

This requires you to target an org and a space. For this example I'll assume `my-org` and `my-space`. I will also assume Pivotal Web Services (PWS).

```sh
$ cf api https://api.run.pivotal.io
$ cf login
# Provide your credentails.
$ cf target -o my-org -s my-space
```

### Push the App

_Note:_ This will not produce a fully funcitoning app, yet. However, we will obtain a routable domain name, which we will need to create a CDN service in the Fastly interface. We will specify a hostname. In this case I will assume `my-fastly-todo`.

```sh
cf push -n my-fastly-todo
```

On PWD this will create a routable domain `my-fastly-todo.cfapps.io`.

### Configure a Fastly service

Create a service in Fastly for your application. Configure your public facing *domain* as `my-fastly-todo.caseywest.com` and your *backend* as `my-fastly-todo.cfapps.io:80`. This will generate a *Service ID*, which we will need later.

### Configure DNS for the Fastly Service Domain

You must configure a CNAME entry for `my-fastly-todo.caseywest.com` which points to `global.prod.fastly.net.`.

### Configure Shared Domains and Routes in Cloud Foundry

Your application hosted on Cloud Foundry already listens to `my-fastly-todo.cfapps.io` but we must also configure it to listen to requests at `my-fastly-todo.caseywest.com`.

First we'll create an owned domain, `caseywest.com`, in our org, `my-org`.

```sh
$ cf create-domain my-org caseywest.com
```

Then we'll map the route for `my-fastly-todo.caseywest.com` to our app:

```sh
$ cf map-route fastly-todo caseywest.com --hostname my-fastly-todo
```

### Create Backing Services

This application relies on an instance of postgres and a Fastly service. First create the postgres instance.

```sh
$ cf create-service elephantsql turtle fastly-todo-pg
```

Next we'll make a "user definded service" to simulate a fully featured service broker for Fastly. We need our Fastly *API Key* and *Service ID*.

```sh
$ cf cups fastly-api -p '{"api_key":"Fastly API Key", "service_id":"Fastly Service ID"}'
```

### Bind Backing Services

Allow the application to interact with its provisioned backing services.

```sh
$ cf bind-service fastly-todo fastly-todo-pg
$ cf bind-service fastly-todo fastly-api
```

### Restart your App

This will inject credentials for postgres and Fastly into new instances of your application. Much modern. So twelve-factor. Wow.

```sh
cf restart fastly-todo
```

### Watch the Magic

First, tail the logs for your application.

```sh
$ cf logs fastly-todo
```

Then, in another terminal window, throw some traffic at it.

```sh
$ ab -c 15 -n 10000 http://my-fastly-todo.caseywest.com/
```

You will observe an initial _cache miss_ being logged for the app as Fastly primes its cache. After that you won't see any other hits to the app because the Fastly CDN has cached the output which hasn't been purged (either manually or through HTTP headers).

## Making this Real

Here are a few things that could be done to make this real:

* A Fastly service broker can be written in Ruby, using their well built and supported [ruby library](https://rubygems.org/gems/fastly). It could:
    - Be configured on install with a Fastly API Key provided by the end-user. This is a per-Cloud Foundry instance of the Fastly service broker.
    - Auto-provision basic Fastly services through cf commands or the Pivotal CF GUI.
* The service broker can be deployed several ways into a Cloud Foundry instance, including as a Cloud Foundry managed application.
* A GUI dashboard can be built for Pivotal Cloud Foundry for more advanced configuration and management of Fastly services.
* Probably more magic I haven't thought of.

:beer:
