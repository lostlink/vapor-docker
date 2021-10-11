

Available Versions:

#### Debian
Images built from php:8.0-fpm
* `php80-debian` => Base PHP Image 
* `php80-debian-octane` => Including Swoole extension for Laravel Octane
* `php80-debian-puppeteer` => With Puppeteer, NodeJS, NPM and Imagick extension
* `php80-debian-octane-puppeteer` => Octane and Puppeteer Images combined

#### Alpine
Images built from php:8.0-fpm-alpine
* `php80-alpine` => Base PHP Image
* `php80-alpine-octane` => Including Swoole extension for Laravel Octane
* `php80-alpine-puppeteer` => With Puppeteer, NodeJS, NPM and Imagick extension
* `php80-alpine-octane-puppeteer` => Octane and Puppeteer Images combined

To build an image:

```shell script
./build.sh php80-debian
```

To build and publish an image:

```shell script
./build.sh php80-debian -p
```

To build all imagea:

```shell script
./build.sh all
```

To build and publish all image:

```shell script
./build.sh all -p
```