library(analogsea)

source("analog-keys.R")

# dpd <- droplet_create(name="dallas-pd-scraper") %>% droplet_wait()
# dpd <- droplet(11366501)

install <- function(droplet){
  droplet %>% 
    droplet_ssh(c("echo 'deb https://cran.rstudio.com/bin/linux/ubuntu trusty/' >> /etc/apt/sources.list",
                  "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9")) %>% 
    debian_apt_get_update() %>% 
    debian_add_swap() %>% 
    debian_install_r() %>% 
    install_rgdal() %>% 
    install_r_package("devtools") %>% 
    install_dallasgeocode() %>% 
    install_phantomjs() %>% 
    debian_apt_get_install("git") %>% 
    install_aws_cli() %>% 
    prepare_dallas_police() %>% 
    add_to_cron
}

prepare_dallas_police <- function(droplet){
  droplet %>% 
    install_r_package(c("RJSONIO", "httr")) %>% 
    droplet_ssh("git clone https://github.com/trestletech/dallas-police.git")
}
  
install_aws_cli <- function(droplet){
  droplet %>% 
    debian_apt_get_install("python-pip") %>% 
    droplet_ssh("pip install awscli") %>%
    droplet_ssh("mkdir -p ~/.aws") %>% 
    droplet_upload("aws-config", "~/.aws/config")
}
  
install_dallasgeocode <- function(droplet){
  droplet %>% 
    droplet_ssh("R -e \"devtools::install_github('trestletech/dallasgeocode', force=TRUE)\"")
}

install_rgdal <- function(droplet){
  droplet %>% 
    debian_apt_get_install("libgdal-dev", "libproj-dev") %>% 
    install_r_package("sp") %>% 
    install_r_package("rgeos") %>% 
    install_r_package("rgdal")
}
  
install_phantomjs <- function(droplet){
  droplet %>% 
    droplet_ssh("wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2",
                "tar xjvf phantomjs-2.1.1-linux-x86_64.tar.bz2",
                "cp phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs",
                "rm phantomjs-2.1.1-linux-x86_64.tar.bz2",
                "rm -rf phantomjs-2.1.1-linux-x86_64")
}

add_to_cron <- function(droplet){
  droplet %>% 
    droplet_ssh("echo '*/2 * * * * ( cd /root/dallas-police/scraper/ && ./exec.sh )' | crontab -")
}