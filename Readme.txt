APP COMMANDS:
cd /home/ubuntu/TickerApp/ && rebar compile generate && ./rel/tickerapp/bin/tickerapp console
sudo ./rel/tickerapp/bin/tickerapp start

EDIT APP FILE:
cd /home/ubuntu/TickerApp/rel/ && sudo nano reltool.config
cd /home/ubuntu/TickerApp/src/ && sudo nano tickerapp_server.erl 

INSTALL iNOTIFY:
sudo apt-get install inotify-tools

MONGO:
mongorestore -d hy dump/hy/
sudo service mongod start
mongo hy

sudo nano sys.config

{emongo, [{pools, [{pool1,
                     [{size, 2},
                      {host, "localhost" },
                      {port, 27017},
                      {database, "hy"}]}  ]
                      }]
                      }

FTP COMMANDS:
tar -zcvf TarFileName.tar DirectoryName
put mput get mget pwd delete ?

FTP REFERENCE:
http://gabrielmagana.com/2014/11/installing-ftp-server-vsftpd-on-an-amazon-ec2-ubuntu-14-04-host/
https://sdykman.com/content/installing-vsftpd-ubuntu-1404-amazon-ec2-instance

REBAR REFERENCE:
http://erlang-as-is.blogspot.in/2011/04/erlang-app-management-with-rebar-alan.html
https://github.com/rebar/rebar/wiki
