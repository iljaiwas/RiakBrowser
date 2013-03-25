## Installing Riak on OS X

You can install the latest version of Riak (right now 1.3) through with Homebrew.

* Install [Homebrew](http://mxcl.github.com/homebrew/)
* Invoke 'brew install riak'

## Starting Riak

You should definitely increase the number of maximum allowed open files before starting risk, especially once you changed the storage engine to LevelDB (required for 'Secondary Index' feature.

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