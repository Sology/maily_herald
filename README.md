# MailyHerald

MailyHerald is a Ruby on Rails engine that helps you sending and managing your mailings. Think of Maily as a self-hosted Mailchimp you can easily integrate with your site. MailyHerald is great both for e-mail marketing and conducting daily stream of notifications you send to your users.

With MailyHerald you can send:
* one-time e-mails (ie. welcome message),
* periodicals (ie. weekly notifications)
* ailing sequences (ie. multiple ordered e-mails delivered with certain delays since the time when user registered on site)

Maily will keep track of users' subscriptions and allow them to easily opt out. You can define who will receive which e-mails and specify conditions that control delivery. All deliveries are tracked and logged.

## Requirements

Only Ruby on Rails 3.2 is supported. We are working on Rails 4 support.

## Installation

Simply just

    gem install maily_herald

or put in your Gemfile

    gem "maily_herald"

## How it works

In order to run successful mailings you need following:

* *Entity* - you probably have this already; enity is a recipient, basically a model you will deliver mail to (like ie. User),
* *Context* - your subscribers - simply a collection of entities,
* *Dispatch* - one-time, periodical or sequence mailing - Maily provides you with that!

## Usage

Maily is fully compatible with standard Rails Action Mailer. There's very little you need to do in order to run your deliveries with Maily.

1. Install Maily engine migrations and run them:

  ```ruby
  rake maily_herald:install:migrations
  rake db:migrate
  ```

2. Assuming you have your User model, create an initializer with definitions of contexts and dispatches:

  ```ruby
  MailyHerald.setup do |config|
    config.default_from = "no-reply@mailyherald.com"

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

MIT License. Copyright 2013-2014 Sology. http://www.sology.eu

Initial development sponsored by Smart Language Apps Limited http://smartlanguageapps.com/
