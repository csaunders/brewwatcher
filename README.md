# BrewWatcher

A little tool for watching and logging your brewing
temperatures.

# Why?

I was looking to get into hardware hacking so figured
this would be the easiest way to do it.

# Whats Required?

My project consists of the following:

- Raspberry Pi for logging/reporting
- Arduino for taking the readings
- DS1307 Real Time Clock for generating timestamps
- DS18B20 Digital Temperature Sensor for temperature readings

There are probably a few other things, but this is all that's needed for the headless version.

# Languages

 - Arduino for all that electronics stuffs
 - golang for something... don't know quite what
 - ruby as my crutch while learning golang
   - I actually want to get this thing done somewhat quickly!

# brewweb

This is a simple webserver written in golang that will serve the information logged to the world, or something.

If you'd like to see how it works, just run `go build brewweb` and you should be good to go.

## Dependencies

* I do rely on the SQLite package, which can be made available by invoking the following command:
** `go get code.google.com/p/gosqlite/sqlite`
* I don't have anything really setup for my database yet so I've included the `seed.sql` file. You can get the database ready to roll by doing the following:

```
$ sqlite3 test.db
> .read seed.sql
> .exit
```