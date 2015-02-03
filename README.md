# MailyHerald

MailyHerald is a Ruby on Rails gem that helps you sending and managing your mailings. Think of Maily as a self-hosted Mailchimp you can easily integrate with your site. MailyHerald is great both for email marketing and conducting daily stream of notifications you send to your users.

With MailyHerald you can send:
* one-time mailings (ie. welcome emails, special offers),
* periodical mailings (ie. weekly notifications, reminders),
* mailing sequences - multiple ordered emails delivered with certain delays since specific point in time (ie. onboarding emails, site feature overview).

Maily keeps track of user subscriptions and allow them to easily opt out. You can define who receives which emails and specify conditions that control delivery. All deliveries are tracked and logged. Periodical and Sequence mailing deliveries are scheduled individually for each recipient.

Maily seamlessly integrates with your app. It can use your regular Mailers or you can build ad-hoc mailings with [Liquid](http://liquidmarkup.org/) markup templates. 

Core Maily features are accessible for Rails programmers via API. Apart from that, Maily has a nice web UI provided by separate [maily_herald-webui](https://github.com/Sology/maily_herald-webui) gem.

## Requirements

Both Ruby on Rails 3.2 and 4 are supported. 

## Installation

Simply just

    gem install maily_herald

or put in your Gemfile

    gem "maily_herald"

## Features

* Designed for Ruby on Rails
* Self-hosted
* Seamless and flexible integration
* Great both for developers (API) and end-users (Web UI) 
* Three different mailing types
* Correspondence logging
* User-friendly subscription management ie. via automatic & personal opt-out links
* Individual delivery scheduling 
* Asynchronous processing
* Mailing conditions
* Ad-hoc email templating using Liquid syntax

## How it works

There are few key concepts that need to be explained in order to understand how Maily works. Some of them are similar to what you might know form other conventional email marketing software. Others come strictly from Ruby on Rails world.

**Entities**

Entities are basically your mailing recipients. They will be probably represented in your application by `User` model.

**Mailings**

You usually send single emails to your users - one at a time. Mailing is a bunch of emails sent out to many users. MailyHerald allows you to send three types of Mailings: one-times, periodicals and sequences.

**Contexts**

Maily Contexts are abstraction layer for accessing collections of Entities and their attributes. 

There are three main things that Contexts do:

* They define sets of Entities via Rails scopes (ie. `User.activated` meaning all application users that activated their accounts). 
* They specify destination email addresses for Entities (ie. you define that `User#email` method returns email address or specify a custom proc that does that).
* They specify additional Entity attributes that can be used inside Mailing templates, conditions etc (basically - attributes accessible via Liquid).

**Lists and Subscriptions**

Lists are sets of Entities that receive certain mailings. Entities are added to Lists by creating Subscriptions. It is entirely up to you how you manage Subscriptions in application. Typically, you put some checkbox in user's profile page that subscribes and unsubscribes them from mailing lists.

Each Subscription has it's unique token allowing users to be provided with one click opt-out link.

**Mailers**

Mailers are standard way of sending emails in Rails applications. MailyHerald hooks into ActionMailer internals and allows you to send Mailings just like you send your regular emails. All you need to do is inherit `MailyHerald::Mailer` in your Mailer. 

There's also a possibility to send Mailings without using any of your custom Mailers. `MailyHerald::Mailer` is in this case used implicitely; email body and subject is stored directly in your Mailing definition as a Liquid template. Liquid gives you acces to Entity attributes defined in the Context. This way of creating Mailings is especially usefull within Web UI where you can build new Mailing by just typing its template.

**Delivery**

MailyHerald uses great gem [Sidekiq](http://sidekiq.org/) to process deliveries in the background. This applies to Periodical and Sequence Mailings - their delivieries are scheduled individually for each Entity on the subscription list. 

Paperboy...

## Usage

Let's assume your entities are your `User` model objects. Read on in order to find out how to start with Maily.

### Migrations

Install engine migrations and run them.

```ruby
rake maily_herald:install:migrations
rake db:migrate
```

### Initializer

Generate and setup an initializer.

```ruby
rails g maily_herald:install
```

This will generate file with following content:

```ruby
MailyHerald.setup do |config|
  # Put your contexts, mailing definitions etc here.
end
```

There are few things you need to put there. 

**Set up your context**

You want to deliver your mailings to all your active users.

```ruby
config.context :active_users do |context|
  context.scope = {User.active}
  context.destination = {|user| user.email}
  
  # Alternatively, you can specify destination as attribute name:
  # context.destination = :email
end
```

**Set up your lists**

This means that all users in `:active_users` context scope can be subscribed to `:newsletters` list.

```ruby
config.list :newsletters do |list|
  list.context_name = :active_users
end
```

**Set up your mailings**

```ruby
config.one_time_mailing :hello do |mailing|
  mailing.title = "Hello mailing"
  mailing.context_name = :active_users
  mailing.mailer_name = "UserMailer"
  mailing.enable # mailings are disabled by default
end

config.periodical_mailing :weekly_newsletter do |mailing|
  mailing.title = "Weekly newsletter"
  mailing.context_name = :active_users
  mailing.mailer_name = "UserMailer"
  mailing.enable
end
```

**Set up your unsubscribe toke actions**
  
```ruby
foo
```

### Mailers

You don't need to have any Mailer to use MailyHerald. It works perfectly fine with its generic `MailyHerald::Mailer` and mailing templates written in Luquid. 

But if you still want your fancy Mailer views and features, you need to modify it a bit.

First, each Mailer you want to use with MailyHerald needs to extend `MailyHerald::Mailer` class. 
Then each Mailer method must accept one and only one parameter which is your Entity (ie. `User` class object).

This setup gives you some extra instance varialbles available in your views:

* `@maily_entity` - Entity you are sending this email to,
* `@maily_mailing` - Mailing you are sending,
* `@maily_subscription` - `MailyHerald::Subscription` object related to this Entity and Mailing,

Here's the complete example:

```ruby
class UserMailer < MailyHerald::Mailer
  def hello user
    mail :subject => "Hi there #{user.name}!"
  end
end
```

### Mounting

To process user unsubscribe requests.

```ruby
foo
```

### Delivery

That's it! From now on, Maily will handle and track your regular mail deliveries:

```ruby
UserMailer.hello(User.first).deliver
```

Of course, you can also run the mailing for all users in scope at once:

```ruby
MailyHerald.dispatch(:hello).run
```

Start MailyHerald Paperboy which will take care of your other periodical and sequence deliveries:

```
$ maily_herald paperboy --start
```

## Configuring

List of config file options...

## Customizing

### Opt-out urls

TODO

## More Information

* api docs
* showcase
* sample app

For bug reports or feature requests see the [issues on Github](https://github.com/Sology/maily_herald/issues).  

## License

LGPLv3 License. Copyright 2013-2014 Sology. http://www.sology.eu

Initial development sponsored by Smart Language Apps Limited http://smartlanguageapps.com/
