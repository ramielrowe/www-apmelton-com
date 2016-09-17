FROM nginx

RUN apt-get update &&  apt-get install python python-dev python-pip git -y

WORKDIR /www-apmelton-com
ADD requirements.txt /www-apmelton-com/requirements.txt
RUN pip install -r /www-apmelton-com/requirements.txt

RUN git clone https://github.com/onlyhavecans/pelican-chunk.git /pelican-chunk && pelican-themes -vi /pelican-chunk && rm -rf /pelican-chunk

ADD . /www-apmelton-com
WORKDIR /www-apmelton-com/site
RUN pelican /www-apmelton-com/site/content -s /www-apmelton-com/site/pelicanconf.py -o /usr/share/nginx/html
