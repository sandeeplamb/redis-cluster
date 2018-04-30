#!/bin/bash
set -e

if [ -n "$DEPLOYMENT" ]
then
	 ### Internal-Cloud-Related ENV Variables	
	 MARATHONDEPLOYMENTNU="$(echo ${MARATHON_APP_ID} | cut -d"/" -f4)"
	 MARATHONDEPLOYMENT="$(echo ${MARATHONDEPLOYMENTNU:: -2})"
	 MARATHONPROJECT="$(echo ${MARATHON_APP_ID} | cut -d"/" -f3)"
	 MESOSIP="$(dig +short ${HOST})"
	 CONSUL="consul"

  	# Get our mapped Mesos IP
  	# Dump our information into our redis.conf
  	sed -i "s/<MESOSIP>/$MESOSIP/g" /etc/redis.conf
  	sed -i "s/<MESOSPORT0>/$PORT_6379/g" /etc/redis.conf
  	sed -i "s/<MESOSPORT1>/$PORT_16379/g" /etc/redis.conf

  	# Start redis with our correct info announced
  	exec 2>&1 redis-server /etc/redis.conf &

	if [ -n "$REDIS_SIX" ]
	then
		# If we're defined as the master, create the cluster
	        echo "One thinks one's the primary."
        	echo "One is going to try and establish the cluster."
        	sleep 40
		
		redis1_ip="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-1-6379 | jq -r '.[-1] | .Service.Address,.Service.Port' | tr "\n" ":" | cut -d":" -f1,2)"
		redis1_port_16379="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-1-16379 | jq -r '.[-1] | .Service.Port')"
		CLREDIS1="${redis1_ip},${redis1_port_16379}"
	
		redis2_ip="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-2-6379 | jq -r '.[-1] | .Service.Address,.Service.Port' | tr "\n" ":" | cut -d":" -f1,2)"
                redis2_port_16379="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-2-16379 | jq -r '.[-1] | .Service.Port')"
		CLREDIS2="${redis2_ip},${redis2_port_16379}"

		redis3_ip="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-3-6379 | jq -r '.[-1] | .Service.Address,.Service.Port' | tr "\n" ":" | cut -d":" -f1,2)"
                redis3_port_16379="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-3-16379 | jq -r '.[-1] | .Service.Port')"
		CLREDIS3="${redis3_ip},${redis3_port_16379}"

                redis4_ip="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-4-6379 | jq -r '.[-1] | .Service.Address,.Service.Port' | tr "\n" ":" | cut -d":" -f1,2)"
                redis4_port_16379="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-4-16379 | jq -r '.[-1] | .Service.Port')"
		CLREDIS4="${redis4_ip},${redis4_port_16379}"

                redis5_ip="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-5-6379 | jq -r '.[-1] | .Service.Address,.Service.Port' | tr "\n" ":" | cut -d":" -f1,2)"
                redis5_port_16379="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-5-16379 | jq -r '.[-1] | .Service.Port')"
		CLREDIS5="${redis5_ip},${redis5_port_16379}"

                redis6_ip="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-6-6379 | jq -r '.[-1] | .Service.Address,.Service.Port' | tr "\n" ":" | cut -d":" -f1,2)"
                redis6_port_16379="$(curl -s http://${CONSUL}:8500/v1/health/service/whc-${MARATHONPROJECT}-${MARATHONDEPLOYMENT}-6-16379 | jq -r '.[-1] | .Service.Port')"
		CLREDIS6="${redis6_ip},${redis6_port_16379}"

    		yes yes | /usr/src/redis-4.0.9/src/redis-trib.rb create --replicas 1 $CLREDIS1 $CLREDIS2 $CLREDIS3 $CLREDIS4 $CLREDIS5 $CLREDIS6
		
		
	fi
else
	echo "Don't think we're running in Cloud"
  	sed -i "s/cluster-announce/#cluster-announce/g" /etc/redis.conf
  	exec 2>&1 redis-server /etc/redis.conf &
fi

while /bin/true
do
	sleep 40
  	REDIS_STATUS=$(ps aux |grep redis-server |grep -v "grep\|tail" > /dev/null ; echo $?)
  	# If the greps above find anything, they will exit with 0 status
  	# If it's not 0, something is wrong
    	if [ $REDIS_STATUS == 1 ]; then
      		echo "Redis doesn't appear to be started. Starting it!"
      		exec 2>&1 redis-server /etc/redis.conf &
    	fi
done

