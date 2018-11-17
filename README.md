# How use it

This is docker is to use vlc to send content to your chromecast, you can use it in several diferent ways, buf before you need to **know your host ip and chromecast ip**, in the project you have some tools to discover it.


## Run with Docker

For example:

```
docker run -it --rm -p 8010:8010 -e CHROMECASTIP=192.168.1.43 -e HOSTIP=192.168.1.39 --name docker-vlc-chromecast  clean-toolbox/vlc-chromecast
```
or

```
docker run -it --rm -p 8010:8010 -e CHROMECASTIP=192.168.1.43 -e HOSTIP=192.168.1.39 --name docker-vlc-chromecast -v $(pwd)/samples:/samples  clean-toolbox/vlc-chromecast -vvv --network-caching=1000 /samples/sample1.mp4 --demux-filter=cc_demux vlc://quit --play-and-exit 
```

## Run with docker-compose

There are some **problems** running with **docker-compose**, check issues section

check docker-compose.yml file

```
docker-compose up
```
compile and run

```
docker-compose -f docker-compose-build.yml up
```
add -d argument if you want run in detached mode

#  Build VLC by yourself

The goal of this is compile a vlc version to allow send content from vlc to chromecast.  vlc inside docker cant send content to the chromecast because it must instance a server that will be inside the docker and behind a host.

Docker container, you should put the chromecast ip on CHROMECAST environment variable

    docker run --name build-vlc-chromecast ubuntu /bin/bash

First will will install all necessary tools:
```
apt-get update -y 
apt-get install git build-essential pkg-config libtool nano gnutls-bin \
				automake autopoint gettext -y
```

After we must bring vlc repository code to compile it

```
git clone git://git.videolan.org/vlc.git
```
Go to source and uncomment all **deb-src** packages with subsection **universe**, and bring all dependencies to compile vlc
```
nano /etc/apt/sources.list
apt-get update
apt-get build-dep vlc -y
```

Usually vlc dont run with root previlges, so you must create a user to do it

```
useradd -m -d /data -s /bin/sh -u 1000 vlc
```

Probably the next  steps you should do it inside a **entrypoint** to docker

Find issuer or common name to chromecast  and update hosts, this is to accept the ssl certificates, to do this you must be able to connect with your chromecast, if not check firewall and if you have your tv in chromecast mode.

    export ISSUER=$(gnutls-cli --print-cert --no-ca-verification $CHROMECASTIP:8009 </dev/null | sed -n '7p' | awk '{split($0,a,"="); print a[3]}' | awk '{split($0,a,"'\''"); print a[1]}')

after check if you have the issuer in variable

     echo $ISSUER

You should see something like: 85436ef3-3379-0849-9a0d-0a46592468de

Update hosts

     echo "$CHROMECASTIP  $ISSUER" >> /etc/hosts

Add issuer as trust root certificate
 

    gnutls-cli --print-cert --no-ca-verification $ISSUER:8009 </dev/null| sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /usr/local/share/ca-certificates/chromecast.crt
    
     update-ca-certificates


Compile vlc to accept HOST_PROXY  enviroment var to set local server to send content to chromecast

The file that you should edit is 

    cd /vlc

nano modules/stream_out/chromecast/chromecast_communication.cpp

in constructor (maybe this will change depends of version )

    ChromecastCommunication::ChromecastCommunication( vlc_object_t* p_module,
        std::string serverPath, unsigned int serverPort, const char* targetIP, unsigned int devicePort )
        : m_module( p_module )
        , m_creds( NULL )
        , m_tls( NULL )
        , m_receiver_requestId( 1 )
        , m_requestId( 1 )
        , m_serverPath( serverPath )
        , m_serverPort( serverPort )
    {
        if (devicePort == 0)
            devicePort = CHROMECAST_CONTROL_PORT;
    
        m_creds = vlc_tls_ClientCreate( m_module->obj.parent );
        if (m_creds == NULL)
            throw std::runtime_error( "Failed to create TLS client" );
    
        m_tls = vlc_tls_SocketOpenTLS( m_creds, targetIP, devicePort, "tcps",
                                       NULL, NULL );
        if (m_tls == NULL)
        {
            vlc_tls_Delete(m_creds);
            throw std::runtime_error( "Failed to create client session" );
        }
    
        char psz_localIP[NI_MAXNUMERICHOST];
        if (net_GetSockAddress( vlc_tls_GetFD(m_tls), psz_localIP, NULL ))
            throw std::runtime_error( "Cannot get local IP address" );
        
         char* host_proxy;
         host_proxy = std::getenv ("HOST_PROXY");

		m_serverIp = psz_localIP;

		 if (host_proxy!=NULL)
		   m_serverIp= host_proxy;
	}

replace 

    m_serverIp= host_proxy;

with 

    char* host_proxy;
    host_proxy = std::getenv ("HOST_PROXY");
    
   		m_serverIp = psz_localIP;
   
   		 if (host_proxy!=NULL)
   		   m_serverIp= host_proxy;


Compile it

    ./bootstrap
    ./configure --enable-chromecast --disable-xcb
    make

Save It

From another console make commit of the actual container and save it with your own [repository\]tag
 
 ```
docker commmit build-vlc-chromecast cleantoolbox\vlc-chromecast
```

Push it

with your docker hub login

```
docker push cleantoolbox\vlc-chromecast
```


## Know issues

There are a important issue that i didnt resolve for now, when you try run with **docker-compose**  the gnutls inside vlc cant resolve CN of chromecast. I dont know if is a docker-compose bug or some option that we should put. Its strange because i use gnutls client to get certificate and get CN of chromecast but after when running inside vlc running something happen.

## Video samples

All the videos in the folder are CC zero so we can use it for demo porpuses.



