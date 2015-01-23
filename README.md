# MailyHerald

MailyHerald is a Ruby on Rails engine that helps you sending and managing your mailings. Think of Maily as a self-hosted Mailchimp you can easily integrate with your site. MailyHerald is great both for email marketing and conducting daily stream of notifications you send to your users.

With MailyHerald you can send:
* one-time emails (ie. welcome emails, special offers),
* periodicals (ie. weekly notifications, reminders)
* mailing sequences - multiple ordered emails delivered with certain delays since specific point in time (ie. onboarding emails, site feature overview)

Maily keeps track of users' subscriptions and allow them to easily opt out. You can define who receives which emails and specify conditions that control delivery. All deliveries are tracked and logged.

## Requirements

Both Ruby on Rails 3.2 and 4 are supported. 

## Installation

Simply just

    gem install maily_herald

or put in your Gemfile

    gem "maily_herald"

## How it works

In order to run successful mailings you need following:

* *Entity* - you probably have this already; enity is a recipient, basically a model you send emails to (like ie. User),
* *Context* - your subscribers - simply a collection of entities,
* *Dispatch* - one-time, periodical or sequence mailing - Maily provides you with that!

## Usage

Maily is fully compatible with standard Rails ActionMailer. There's very little you need to do in order to run your deliveries with Maily.

1. Install Maily engine migrations and run them:

  ```ruby
  rake maily_herald:install:migrations
  rake db:migrate
  ```

2. Assuming you have your User model, create an initializer with definitions of contexts and dispatches:

  ```ruby
  MailyHerald.setup do |config|
    config.context :active_users do |context|
      context.scope {User.active}
      context.destination {|user| user.email}
    end

    config.one_time_mailing :hello do |mailing|
      mailing.title = "Hello mailing"
      mailing.context_name = :active_users
      mailing.mailer_name = "UserMailer"
      mailing.enabled = true
    end
  end
  ```

3. Adjust your current Mailer a bit:

  ```ruby
  class UserMailer < MailyHerald::Mailer
    def hello user
      mail :subject => "Test"
    end
  end
  ```

4. Thats it! From now on, Maily will handle and track your regular mail deliveries:

  ```ruby
  UserMailer.hello(User.first).deliver
  ```

  Of course, you can also run the mailing for all users in scope at once:

  ```ruby
  MailyHerald.dispatch(:hello).run
  ```

5. Start MailyHerald Paperboy which will take care of your other periodical and sequence deliveries:

  ```
  $ maily_herald paperboy --start
  ```

## More Information

Please see the [MailyHerald wiki](https://github.com/Sology/maily_herald/wiki) for the official documentation. You'll find there some information about other dispatches that Maily supports: Periodicals and Sequences.

For bug reports or feature requests see the [issues on Github](https://github.com/Sology/maily_herald/issues).  

## License

LGPLv3 License. Copyright 2013-2014 Sology. http://www.sology.eu

Initial development sponsored by Smart Language Apps Limited http://smartlanguageapps.com/
