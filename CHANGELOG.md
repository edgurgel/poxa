# Changelog

## 0.3.0 (2014-09-13)

* Drop lager and use Elixir Logger instead;
* Add integration tests to most events;
* Update packages;
* Change releases to not include Erlang binaries.

## 0.2.0 (2014-08-01)

* The cacertfile file is optional now to run using SSL. Thanks to @darrencauthon!
* Ensure support to Elixir ~> 0.14.2;
* Update deps.

## 0.1.0 (2014-05-24)

* Use extracted library Signaturex to validate HTTP signed requests;
* Add lifetime to disconnection event on Console;
* Update to Elixir 0.13.*;
* Use Maps where ListDicts were before;
* Use hex dependencies where possible (JSEX and Signaturex);
* Use exrm to release.

## 0.0.8 (2014-04-21)

* Upgrade to Elixir 0.12.4;
* Update dependencies;
* Return correct error codes on non supported protocol and wrong app_key;
* Support only Pusher Protocol between 5-7;
* Add real-time Console to follow events happening on Poxa.

## 0.0.7 (2014-01-20)

* Upgrade to Elixir 0.12.1;
* Add simple integration test;
* Support protocol 7;
* Check for protocol when connecting websockets;
* Update deps;
* Remove deprecated code on crypto.

## 0.0.6 (2013-08-23)

* Fix user_id sanitization
* Use just one process property for presence channels
* Upgrade to Elixir 0.10.1

## 0.0.5 (2013-07-29)

* Remove duplicated userinfo on presence subscription success;
* Use `gproc:goodbye/0` instead of automatic cleanup for performance reasons;
* Remove shared counters and use simple `gproc` properties.

## 0.0.4 (2013-07-26)

* Fix the way we check connections from the same user on presence-channels. This was leading to a critical error on presence channels;
* Update JSEX dependency.

## 0.0.3 (2013-07-24)

* Update to Elixir 0.10.0;
* Add partial support to REST api:
  * /channels
  * /channels/:channel_name
  * /channels/:channel_name/users
* Add automated releases using relex;
* Bugfixes.
