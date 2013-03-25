#About Riak Browser

This is a basic OS X utility for interacting with the [Riak](http://basho.com/riak/) database.

##What Riak Browser lets you do:

* Store objects in a Riak database
* Retrieve objects stored in a Riak database
* Add and view secondary indexes
* Find stored object using secondary indexes

## What do I need to run it

* Xcode (I used 4.6.1, but older versions should be fine, too)
* Mac OS X 10.7 and up (the project's base SDK is set to 10.8, mainly because I couldn't get the current AFNetworking source to compile with the 10.7 SDK)
* a working [CocoaPods](http://docs.cocoapods.org/guides/installing_cocoapods.html) installation (perform a 'pod install' after checkout)


## What's still missing

* Support for Riak's full text search
* Syntax coloring for content text view (JSON and XML)


# Working with Riak

## Installing Riak on OS X

You can install the latest version of Riak (right now 1.3) through with Homebrew.

* Install [Homebrew](http://mxcl.github.com/homebrew/)
* Invoke 'brew install riak'

## Starting Riak

You should definitely increase the number of maximum allowed open files before starting risk, especially once you changed the storage engine to LevelDB (required to use Riak's 'Secondary Index' feature).

* ulimit -n 4096
* riak start

There should be an 'run_erl' process running on your machine now. To get rid of it, simply use:

* riak stop

## Enabling Secondary Indexes

Riak's [Secondary indexes](http://docs.basho.com/riak/latest/tutorials/querying/Secondary-Indexes/) allow for easy retrieval of your stored data. Unfortunately they are not supported by the storage backend enabled in Riak's default installation.

Follow these steps to enable secondary indexes:

* Open Riak 'app.config' file in a text editor of your choice. For the current version, that should be '/usr/local/Cellar/riak/1.3.0-x86_64/libexec/log'.
* In 'app.config' search for 'storage_backend' and replace the default value 'riak_kv_bitcask_backend' with 'riak_kv_eleveldb_backend'
* After invoking 'riak start' check the Riak is indeed running by calling 'riak ping'. If not, check Riak's log what caused it to shut down. Hint: You can increase the number of open files in the current environment with 'ulimit -n 4096'. 

## Further Riak Reference

You can learn a lot more about Riak from the [Riak Handbook](http://riakhandbook.com) by Matthias Meyer.