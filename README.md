# au3-network-bottleneck-tool
Network bottleneck testing tool, written in AU3.

**How to use:**

* Open up the tool and insert a DNS name or an IP in both slots, one on the one side of your suspected bottleneck and one on the other side.
* Adjust the ping thresholds to expected levels for your network in ms.
* Then press start and watch the tool do continuous ping tests.

It will show the status of the tests in the display, as well as put the results in *log.txt*.
Should any ping thresholds be broken, it will be marked with several exclamation marks like so: "!!!!"