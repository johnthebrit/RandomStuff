#add user to the docker group so has access to the socket avoiding need for sudo on every command
sudo usermod -aG docker $USER


#Basic information
docker --version #note we have both a client and server side
docker system info

#Linux images
docker pull ubuntu
docker image inspect ubuntu
#Note because we are using docker it automatically uses its registry however underlying components like containerd are NOT opiniated
#Docker is adding its registry (Docker Hub) to the name entered, e.g. what is actually being pulled is:
docker pull docker.io/library/ubuntu:latest
#starting deteched -d but interactive -it so bash has a terminal to attach to and not exit straight away
docker run --name ubuntu -dit --memory=256m --cpus="2" ubuntu bash

docker pull alpine
docker run --name alpine -dit alpine /bin/sh

#From a different registry
docker pull mcr.microsoft.com/cbl-mariner/base/core:2.0
docker run --name mariner -dit mcr.microsoft.com/cbl-mariner/base/core:2.0 bash
cat /etc/os-release
docker exec mariner cat /etc/os-release

#list containers
docker ps -a

#get detail for our container
dockid=$(docker ps -a -q --filter "name=ubuntu")
dockerlongid=$(docker ps  -a -q --no-trunc --filter "name=ubuntu")
dockerPSID=$(ps aux | grep -v grep | grep $dockid | awk '{print $2}')

#Container configurations stored:
sudo du -hc --max-depth=1 /var/lib/docker/containers/
sudo ls -l /var/lib/docker/containers/$dockerlongid
sudo cat /var/lib/docker/containers/$dockerlongid/config.v2.json


#If stopped
docker start $dockid
docker attach $dockid  #Ctrl P Q to exit and leave running. Or exit to stop
#if in vs code add "terminal.integrated.sendKeybindingsToShell": true, to settings to stop Ctrl+P going to app


#Cgroups

#How many cgroups
cat /proc/cgroups

#My cgroup
cat /proc/$$/cgroup
#cgroup of the docker process
cat /proc/$dockerPSID/cgroup
#cgroup of the process WITHIN the container that has parent of the runc instance
containerbash=$(ps -eF | grep -v grep | grep bash | grep $dockerPSID | awk '{print $2}')
cat /proc/$containerbash/cgroup

#Cgroup controllers available (V2)
cat /sys/fs/cgroup/cgroup.controllers
cat /sys/fs/cgroup/cgroup.subtree_control #active

#To view the cgroup (in this case v2 with systemd driver)
ls /sys/fs/cgroup/system.slice
#Various metrics https://docs.docker.com/config/containers/runmetrics/
#Processes in the containerd cgroup
cat /sys/fs/cgroup/system.slice/containerd.service/cgroup.procs

#Our container cgroup
ls /sys/fs/cgroup/system.slice/docker-$dockerlongid.scope/

#Processes in this cgroup
cat /sys/fs/cgroup/system.slice/docker-$dockerlongid.scope/cgroup.procs
cat /sys/fs/cgroup/system.slice/docker-$dockerlongid.scope/pids.current #how many

#Limits applied based on --memory=256m --cpus="2"
#This will show in terms of cpu-quota and cpu-period but is equivalent to 2 https://docs.docker.com/config/containers/resource_constraints/#cpu
cat /sys/fs/cgroup/system.slice/docker-$dockerlongid.scope/cpu.max
cat /sys/fs/cgroup/system.slice/docker-$dockerlongid.scope/memory.max

#sudo apt install cgroup-tools
lscgroup


##Namespaces
#mine
sudo ls -l /proc/$$/ns
#docker process
sudo ls -l /proc/$dockerPSID/ns
#process in our container
sudo ls -l /proc/$containerbash/ns
#The actual values don't mean much to us but note they are different for cgroup, ipc, mnt, net, pid and uts
#Means will have a different visibility when in a different namespace

#on the host
#-e all process -F full format
ps -eF
#Now run same inside the container
docker exec ubuntu ps -ef
#Tiny number. It's only seeing its process.
#It IS present in the parent list of all processes as a child of the runc process that is the runtime for containers

#burn some CPU
docker exec ubuntu sh -c "for i in $(seq 1); do yes > /dev/null & done"
ps -eF
docker exec ubuntu ps -eF
#On host and not it’s the same and can see child of bash parent of runc container runtime
# STIME - time was started and can see the CPU matches
docker exec ubuntu kill <pid>


#Networking
docker network ls
docker network inspect bridge
#view the network namespaces
sudo lsns -t net
#Everything is in the same network namespace except the process running in the container

ip link
#Note we have the physical adapter (eth0), the docker bridge and then a virtual adapter (veth) for the container

#inside the container. Note, this is why later our writable layer is pretty big. Normally would not do this
docker exec apt update
docker exec apt install iproute2 -y
docker exec ubuntu ip link
#it has its view



## Filesystem
#View the storage driver information. overlay2 used
docker info
#see the file system. Care about the GraphDriver section
docker container inspect ubuntu

#Will see the base image and then additional temporary thin layer that is writable on top of the read-only image

#Docker view of the container sizes (the first size is the writable layer size, and the bracket the combined size)
docker ps --size

sudo ls -l /var/lib/docker/overlay2
#This shows each layer. Note the containers size containers both /merged and its /diff so size will be inflated
#but /merged is just a combined view, it does not actually COPY all the data
sudo du -hc --max-depth=1 /var/lib/docker/overlay2/
docker container inspect ubuntu | grep 'MergedDir'

#Grab it using RegEx to output only matched parts using Perl RegEx (-oP) and positive lookbehind (?<= first string then postive look ahead ?= second string)
REGEX_MOUNT="(?<=docker/overlay2/).*?(?=/merged)"
containerImageRef=$(docker container inspect ubuntu | grep 'MergedDir' | grep -oP "${REGEX_MOUNT}")

#Here we see the combined size of /merged view, and then the actual data stored size in /diff
sudo du -hc --max-depth=1 /var/lib/docker/overlay2/$containerImageRef/

#Note the -init contains core files and directories required for docker
sudo ls /var/lib/docker/overlay2/$containerImageRef-init
#I want to use the tree command for better views and have already run on this box
#sudo apt-get install tree
sudo tree /var/lib/docker/overlay2/$containerImageRef-init/diff
#It's parent will be the image the container is executed using and stored in file lower. This won't be present on the lowest layer
sudo cat /var/lib/docker/overlay2/$containerImageRef-init/lower
sudo ls -l /var/lib/docker/overlay2/l
#Lets check the Ubuntu which only has one layer and is the "base" layer so should have no parent
ubuntuImageRef=$(docker image inspect ubuntu | grep 'MergedDir' | grep -oP "${REGEX_MOUNT}")
sudo ls /var/lib/docker/overlay2/$ubuntuImageRef

#Its symbolic link name to itself is stored in link file
sudo cat /var/lib/docker/overlay2/$containerImageRef-init/link


#This is the content of the UpperDir, i.e. the writable, temporary container layer
sudo ls /var/lib/docker/overlay2/$containerImageRef
#It will only have the files created/modified/deleted since container creation from that of the base image
sudo du -hc --max-depth=1 /var/lib/docker/overlay2/$containerImageRef/diff/
sudo ls /var/lib/docker/overlay2/$containerImageRef/diff/

docker exec ubuntu touch hello.world
sudo ls /var/lib/docker/overlay2/$containerImageRef/diff/
sudo touch /var/lib/docker/overlay2/$containerImageRef/diff/hellofrom.host
docker exec ubuntu ls
sudo tree /var/lib/docker/overlay2/$containerImageRef/diff/
#Magic!

#View the mounts using overlay. Note it uses the 'l' symnbolic links to keep the paths shorter to overcome limitations on the mount arguments
sudo ls -l /var/lib/docker/overlay2/l
mount | grep overlay
#Note the LowerDir is the -init and then the base layers.

#The final view of the container is therefore
sudo ls /var/lib/docker/overlay2/$containerImageRef/merged


#An image with multiple layers
#Apache image
docker images
docker search --filter is-official=true httpd
docker pull httpd
docker image history httpd #view the layers
docker image inspect httpd #detailed info about image

#We can see all the layers
sudo ls -l /var/lib/docker/overlay2/

#docker run --name httpdrun -dit --publish 8080:80 httpd bash

cd /mnt/c/users/john/onedrive/projects/git/randomstuff/docker/badfatherapache
docker build -t badfather .
docker images

docker image history badfather #view the layers
docker image inspect badfather #detailed info about image

#Note the content in the top layer of the image, its the data we copied in
badfatherImageRef=$(docker image inspect badfather | grep 'MergedDir' | grep -oP "${REGEX_MOUNT}")
sudo tree /var/lib/docker/overlay2/$badfatherImageRef/diff

#Run it. Also publish to the host 8080 the containers port 80
docker run -dit --name badfather-app --publish 8080:80 badfather
dockbadid=$(docker ps -a -q --filter "name=badfather-app")
docker stop $dockbadid
docker rm $dockbadid
docker rmi badfather
docker rmi httpd


#Note we can push volumes from the host into the container when needing durable, possibly more performance storage
docker stop $dockid
docker rm $dockid

#Project my folder to /stuff in the container
docker run --name ubuntu -dit --volume /mnt/c/users/john/onedrive/projects/git/randomstuff:/stuff ubuntu bash
docker exec ubuntu ls /stuff


#Can be different distributions
#Note I don't have to pull the image first!
docker run --name mariner -dit mcr.microsoft.com/cbl-mariner/base/core:2.0 bash
cat /etc/os-release
docker exec mariner cat /etc/os-release


#See the containerd shim
pstree -lpTs
ctr


#Cleanup my containers and images
docker stop mariner
docker rm mariner
docker rmi mcr.microsoft.com/cbl-mariner/base/core:2.0
docker stop ubuntu
docker rm ubuntu
docker rmi ubuntu

#Clean up everything left over (images, build cache, stopped containers, networks)
docker system prune