# Docker Nginx + PageSpeed + GeoIP + VTS module with PHP-FPM 7.0
This is docker engine image based on [Alpine](https://hub.docker.com/_/alpine/) with embeded docker health check.

## Credits
- [lagun4ik for original Nginx build] https://github.com/lagun4ik/docker-nginx-pagespeed
- [vozlt VTS for module] https://github.com/vozlt/nginx-module-vts
- [openresty for ability to set extra headers with nginx ] https://github.com/openresty/headers-more-nginx-module
- [yaoweibin for ability to replace strings in nginx output] https://github.com/yaoweibin/ngx_http_substitutions_filter_module
- [google for pagespeed] https://github.com/pagespeed

## PageSpeed
The [PageSpeed](https://developers.google.com/speed/pagespeed/) tools analyze and optimize your site following web best practices.

## Components versions

 - [Nginx 1.13.2] (http://nginx.org/en/download.html)
 - [PageSpeed 1.11.33.4] (https://developers.google.com/speed/pagespeed/module/)
 - [PHP-FPM 7.0] (http://php.net/downloads.php)
 
 ## Configuration
 - /healthcheck - provides PHP-FPM ping/pong response, so docker will be able to mark container as unhealthy if PHP or Nginx is not able to process requests
 - :8080/status - PHP-FPM status
 - :8080/ - VTS vhosts modules report

