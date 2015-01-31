# MailyHerald

MailyHerald is a Ruby on Rails gem that helps you sending and managing your mailings. Think of Maily as a self-hosted Mailchimp you can easily integrate with your site. MailyHerald is great both for email marketing and conducting daily stream of notifications you send to your users.

With MailyHerald you can send:
* one-time mailings (ie. welcome emails, special offers),
* periodical mailings (ie. weekly notifications, reminders),
* mailing sequences - multiple ordered emails delivered with certain delays since specific point in time (ie. onboarding emails, site feature overview).

Maily keeps track of user subscriptions and allow them to easily opt out. You can define who receives which emails and specify conditions that control delivery. All deliveries are tracked and logged.

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
* Seamless integration
* Great both for developers (API) and users (Web UI) 
* Three different mailing types
* Correspondence logging

## How it works

There are few key concepts that need to be explained in order to understand how Maily works. Some of them are similar to what you might know form other conventional email marketing software. Others come strictly from Ruby on Rails world.

**Entities**

Entities are basically your mailing recipients. They will be probably represented in your application by `User` model.

**Mailings**

You usually send single emails to your users - one at a time. Mailing is bunch of emails sent out to many users. MailyHerald handles three types of Mailings: one-time, periodical and sequence.

**Contexts**

Maily Contexts are abstraction layer for accessing groups of Entities and their attributes. 

There are three main things that Contexts do:

* They define sets of Entities via Rails scopes (ie. `User.activated` meaning all application users that activated their accounts). 
* They specify destination email addresses for Entities (ie. defines that `User#email` attribute contains email address).
* They specify additional Entity attributes that can be used inside Mailing templates, conditions etc (basically - attributes accessible via Liquid).

**Lists and Subscriptions**

Lists are sets of Entities that receive certain mailings. Entities are added to Lists by creating Subscriptions. It is entirely up to you how you manage Subscriptions in application. Typically, you put some checkbox in user's profile page that subscribes and unsubscribes them from mailing lists.

**Mailers**

Mailers are standard way of sending emails in Rails applications. MailyHerald hooks into ActionMailer internals and allows you to send Mailings just like you send your regular emails.

Maily can use your Rails Mailers you use on daily basis. In this case, nothing really changes in terms of composing and sending emails. 

There's also one special mailer that MailyHerald provides: `GenericMailer`. It is used by Mailings which don't have their own Mailer in the app. Those Mailings store their subject and body as Liquid templates and `GenericMailer` takes care of rendering them. Liquid gives you acces to Entity attributes defined in the Context. It is especially usefull within Web UI where you can create new Mailing by just typing its template.

## Usage

Maily is fully compatible with standard Rails ActionMailer. There's very little you need to do in order to run your deliveries with Maily.

1. Install Maily engine migrations and run them:

  ```ruby
  rake maily_herald:install:migrations
  rake db:migrate
  ```

1. Generate an initializer:

  ```ruby
  rails g maily_herald:install
  ```

1. Assuming you have your `User` model, add definitions of contexts and dispatches to your initializer:

  ```ruby
  # config/initializers/maily_herald.rb
  MailyHerald.setup do |config|
    config.context :active_users do |context|
      context.scope = {User.active}
      context.destination = {|user| user.email}
    end

    config.list :

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
      mailing.enable # mailings are disabled by default
    end
  end
  ```

1. Adjust your current Mailer a bit:

  ```ruby
  class UserMailer < MailyHerald::Mailer
    def hello user
      mail :subject => "Test"
    end
  end
  ```

1. Thats it! From now on, Maily will handle and track your regular mail deliveries:

  ```ruby
  UserMailer.hello(User.first).deliver
  ```

  Of course, you can also run the mailing for all users in scope at once:

  ```ruby
  MailyHerald.dispatch(:hello).run
  ```

1. Start MailyHerald Paperboy which will take care of your other periodical and sequence deliveries:

  ```
  $ maily_herald paperboy --start
  ```

## More Information

Please see the [MailyHerald wiki](https://github.com/Sology/maily_herald/wiki) for the official documentation. You'll find there some information about other dispatches that Maily supports: Periodicals and Sequences.

For bug reports or feature requests see the [issues on Github](https://github.com/Sology/maily_herald/issues).  

## License

LGPLv3 License. Copyright 2013-2014 Sology. http://www.sology.eu

Initial development sponsored by Smart Language Apps Limited http://smartlanguageapps.com/
