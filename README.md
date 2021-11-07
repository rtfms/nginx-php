**Run nginx and php-fpm in your development environment in minutes!**

This docker image includes nginx v1.19.4 and php-fpm v7.4 configured to support mysqli, gd (with freetype and jpeg), 
mcrypt, ssl, flv, mp4 and more. Nginx is compiled from the source code, so you can easily add additional modules. 
php-fpm loads modules via  docker-php-ext-* so you can add additional modules to it too. It is also preconfigured to 
pseudostrem mp4 and flv files (see http://nginx.org/en/docs/http/ngx_http_mp4_module.html) and supports uploading large 
files (up to 100Mb). 

# How to run
You can skip these environment variables and specify the paths directly in the `docker run` command, I added them just to make it easier to keep things in one place
* `NGINX_PHP_BASE_DIR=/docker_data/nginxphp` - this is where you want to keep all system files including the configuration, 
and the logs 
* `NGINX_PHP_WWW_DIR=/docker_data/www` - this is where you plan to keep the web server content
* The following command will do all the magic including configuring nginx, in the case if you do not have your own 
configuration file. After the container start you can edit the configuration files in 
${NGINX_PHP_BASE_DIR}/nginx_etc and add things like SSL configuration of vhosts, but the default config is sufficient 
to host one web app

`docker run -d --restart=unless-stopped --name nginxphp -v ${NGINX_PHP_BASE_DIR}/nginx_etc:/etc/nginx -v ${NGINX_PHP_BASE_DIR}/nginx_log:/var/log/nginx -v ${NGINX_PHP_BASE_DIR}/php_log:/var/log/php-fpm -v ${NGINX_PHP_WWW_DIR}:/www -p 8080:80 rtfms/nginx-php`

* Go to http://localhost:8080 in your browser, and you will see the web server running

# What does this command do
Let's see what's in this docker command:
* `docker run` - means "start the docker container from the image"
* `-d` - will run it in the background, so this command won't block your terminal
* `--restart=unless-stopped` - if you will restart Docker (or your server/computer) this will restart the container when 
the docker daemon will start again
* `--name nginxphp` - gives a name to the docker container, makes it easier to manage it once it's running
* `-v ${NGINX_PHP_BASE_DIR}/nginx_etc:/etc/nginx` - this will persist nginx configuration files in ${NGINX_PHP_BASE_DIR}/nginx_etc. 
This and the rest of the `-v HOST_DIR:CONTAINER_DIR` configuration parameters map directories from your computer to the 
container's file system so that the files in these directories could persist between the container restarts. If you do 
not want to persist the logs and totally fine with the default configuration files then you can omit most of the `-v ...` 
options. 
* `-v ${NGINX_PHP_BASE_DIR}/nginx_log:/var/log/nginx` - this is where nginx logs will be saved
* `-v ${NGINX_PHP_BASE_DIR}/php_log:/var/log/php-fpm` - where to keep php logs
* `-v ${NGINX_PHP_WWW_DIR}:/www` - location of the web server content. This is likely the one `-v` option that you will want to keep, 
otherwise the container will keep serving the default nginx page.
* `-p 8080:80` - this tells docker to map the web server to port 8080. You can change this to whatever port you need
* `rtfms/nginx-php` - this is the name of the docker image

# How to change nginx and php configuration
* One way is to edit the configuration files in the host directories mounted in the container and then restart the container, 
but this approach is slow and error prone
* A better way is to 
  * Run shell in the docker container: `docker exec -it nginxphp bash`
  * Edit the configuration files either in the container (it has vi, telnet and some other useful debugging utilities) or
  on the host filesystem using the host utilities
  * If you edited php configs then you can just kill it and start again. A better approach is to send USR2 signal to 
  it: `killall -USR2 php-fpm` and make it reload the configs.
  * If you edited nginx config you should not kill the process because this will kill the container. Instead,
    * Verify that your configuration change is valid: `nginx -t` and fix the errors if any
    * Send HUP signal to nginx: `killall -HUP nginx` to make it reload the configuration files.
 
# How to run Wordpress using this container
1. Start the webserver as shown above
2. Start MariaDB (or Mysql) as a separate container, if necessary (see https://hub.docker.com/_/mariadb for details)
3. Download Wordpress and unpack it to ${NGINX_PHP_WWW_DIR}
4. Go to http://localhost:8080 and configure your Wordpress instance 

# How to build it locally
* Checkout the git repository: git clone https://github.com/rtfms/nginx-php.git
* Modify the Dockerfile if necessary
* Build the image: `docker build -t nginx-php .`
* When you will need to run the new docker image, use `nginx-php` instead of `rtfms/nginx-php`

# Can I use this image in production?
You can, with the proper security measures (like configuring the filrewall, LIDS, antivirus etc) and after providing 
appropriate configuration files. However, this image is more optimized specifically for development. 
It includes certain tools (compilers, network utilities, editors etc) that make developing the web server configuration
easier, but also make the image bloated and, thus, less secure. So whether to use this image in the production or not
depends on your specific goals. 

Another thing worth noting is that this image is against the Docker paradigm which includes the idea of running primitive 
services in their own docker containers. This container includes both nginx and php-fpm, which, in ideal world, should 
be split into separate images and started together using docker-compose or a similar tool. This approach is not very
convenient though, because:
- hub.docker.com does not support docker-compose.yml files (at least at the moment)
- docker-compose is an executable separate from docker and may or may not be installed on the target system
- fewer containers are easier to manage, just IMHO 

I hope that this image could be a good foundation for the production config after you edit the Docker file, and the
config files to meet your specific configuration and security needs and then remove all unnecessary modules and tools
from it by updating the Dockerfile.
