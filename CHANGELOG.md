# Changelog

## 0.6.0 (2016-05-29)

* Automate docker build: https://hub.docker.com/r/edgurgel/poxa-automated/
* Webhooks (Thanks to @iurifq 🎉 ) #60 #72
* Add channel vacated and occupied events to console (Thanks to @iurifq 🎉 ) #70
* Extract gproc to be an adapter #74
* Update deps in general

## 0.5.0 (2015-12-14)

* Update `cowboy` and `ranch`

## 0.4.3 (2015-09-03)

* Add edip dependency to generate docker images
* Update exrm
* Validate channel name according to pusher docs (waffleio#4). Thanks to @burtonjc :tada:

## 0.4.2 (2015-07-10)

* Add missing configuration steps for releases with SSL enabled

## 0.4.1 (2015-07-06)

* Fix pusher:error generation;
* Refactor internals;
* Add missing websocket_handle for ping frames;

## 0.4.0 (2015-05-31)

* Refactor internal modules Authentication and PusherEvent;
* Document several modules;
* Validate channel name and socket id on Events endpoint;
* Generate socket id using the pattern "NUMBER.NUMBER" according to Pusher's format;

## 0.3.3 (2015-02-22)

* Refactor internals (Console, EventsHandler, Subscription, etc)
* Add filter_by_prefix to /channels endpoint. Thanks to @tobycox

## 0.3.2 (2014-10-16)

* Fix Poxa console to work also on SSL connections. Thanks to @darrencauthon !;
* Ensure double JSON encoding on data keys on events;
* Refactor some parts to improve readability;
* Drop support to Elixir 0.15.*;
* Fix unsubscription on Presence channels.

## 0.3.1 (2014-09-16)

* Refactor channel specific code to Channel and PresenceChannel modules;
* Use [conform](http://github.com/bitwalker/conform) to configure releases;

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
