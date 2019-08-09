# pure2influx
A perl script to gather statistics about Pure Storage arrays and send the data to InfluxDB for display on a Grafana dashboard

This script is a modified version of https://github.com/purestorage/graphite-grafana.
I found it a lot easier to modifiy this script to print statistics in InfluxDB line protocol
compared to having to configure the Graphite Input plugin in InfluxDB. I added two helpful fields (location & enviornment) that make querying in Grafana easier.

## Requirements
- Perl
- [API::PureStorage](https://metacpan.org/pod/API::PureStorage) module and its dependencies (run `cpan API::PureStorage`)

## Configuring the Pure Array
The Pure REST API is available for automation and monitoring Pure Storage arrays. It 
provides a secure way of retrieving details about the array.

You will need to generate an API token for usage in the script.
Generating a token is the only array-side configuration required. 

### Creating a user
You can use an existing user if you prefer. Its best practice to use a user who only has read-only permissions.
1. Login to your pure storage array via the WebUI and navigate to Settings > Users.
2. Create a new user named readonly with a role of Read-Only and set a random password
3. Click on the 3 dots and select Create API Token
4. Set the expiration to something long like 521 weeks (10 years)
5. Copy the API token for use in the script

### Configuring InfluxDB
It is assumed you have a working InfluxDB server that is listening on the default port of 8086 for HTTP POST requests. 
Create a new database on your influxDB server named purestats: `influx -execute 'CREATE DATABASE purestats'`

### Sending data to InfluxDB with pure2influx.pl
pure2influx.pl can query one or more Pure arrays (via their API) and return the data in [InfluxDB line protocol format](https://docs.influxdata.com/influxdb/v1.7/write_protocols/line_protocol_tutorial/)

Edit lines 15-17 to include the hostname, api token, location, and enviornment of the array(s) you want to query. The script will query each of these arrays. 
The purpose of the location and enviornment fields is so you can easily aggregate statistics in grafana across arrays by datacenter location or enviornment. Examples of values are located in the script.

This script outputs the formatted data via STDOUT. Using netcat you can then send 
that data to your InfluxDB server. It is common to set this command to be a regular
cron job: `*/5 * * * *  /usr/bin/perl pure2influx.pl |curl -o /dev/null -s -i -XPOST 'http://influxdb.mycompany.com:8086/write?db=purestats' --data-binary @-`

### Example output of pure2influx.pl
Hostname is "TEST-PURE01" Volume names are "customerdata01", "testdata01", "internaldata01", "backups01", and "backups02". Location is LAX and Enviornment is Customer

Example output:
```
purity.array.stats,host=TEST-PURE01,location=LAX,environment=Customer totalreduction=16.9749294344776,datareduction=9.7241640942693,volumes=1632841897232,sharedspace=310338424112,snapshots=0,system=0,total=1943180321344,capacity=3501193959106,thinprovisioning=0.427145536492268
purity.volume.stats,host=TEST-PURE01,volume=customerdata01,location=LAX,environment=Customer totalreduction=11.5866444902504,datareduction=9.93051050969082,snapshots=0,total=257506430343,size=3298534883328,thinprovisioning=0.142934736795723
purity.volume.stats,host=TEST-PURE01,volume=testdata01,location=LAX,environment=Customer totalreduction=11.6488468551881,datareduction=9.63551777414532,snapshots=0,total=256699227385,size=3298534883328,thinprovisioning=0.172835054496924
purity.volume.stats,host=TEST-PURE01,volume=internaldata01,location=LAX,environment=Customer totalreduction=19.3385316599098,datareduction=10.651079614043,snapshots=0,total=151781215701,size=3298534883328,thinprovisioning=0.449230179345856
purity.volume.stats,host=TEST-PURE01,volume=backups01,location=LAX,environment=Customer totalreduction=23.6016576099351,datareduction=8.61046389500594,snapshots=0,total=130323604852,size=3298534883328,thinprovisioning=0.635175459397336
purity.volume.stats,host=TEST-PURE01,volume=backups02,location=LAX,environment=Customer totalreduction=28.6036593796541,datareduction=9.36906393772665,snapshots=0,total=105183667186,size=3298534883328,thinprovisioning=0.672452261671424
```

### Creating graphs in Grafana
Full instructions for the usage of Grafana is outside of the scope of this document. An example dashboard has been published at https://grafana.com/grafana/dashboards/10705

Here is the schema for the data. There are two measurements in the database.
```
> show measurements on purestats;
name: measurements
name
----
purity.array.stats
purity.volume.stats
```

There are 9 field keys for purity.array.stats and 6 for purity.volume.stats
```
> show field keys on purestats
name: purity.array.stats
fieldKey         fieldType
--------         ---------
capacity         float
datareduction    float
sharedspace      float
snapshots        float
system           float
thinprovisioning float
total            float
totalreduction   float
volumes          float

name: purity.volume.stats
fieldKey         fieldType
--------         ---------
datareduction    float
size             float
snapshots        float
thinprovisioning float
total            float
totalreduction   float
```

### Community
Want to contribute, or have comments? Feel free to open an [issue](https://github.com/Gelob/pure2influx/issues/new)
