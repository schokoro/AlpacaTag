FROM nvidia/cuda:10.2-devel-ubuntu18.04
LABEL maintainer="Sergey Ustyantsev ustyantsev@gmail.com"

RUN apt-get clean && apt-get update && apt-get install -yqq curl && apt-get clean

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash

RUN ln -fs /usr/share/zoneinfo/Russia/Moscow /etc/localtime
ENV DEBIAN_FRONTEND noninteractive

# https://github.com/pyenv/pyenv/wiki#suggested-build-environment see at the required dependencies for pyenv
RUN apt-get install -yqq build-essential cmake curl gfortran git graphviz libatlas-base-dev \
        libatlas3-base libblas-dev libbz2-dev libffi-dev libfreetype6-dev libhdf5-dev liblapack-dev \
        liblapacke-dev liblzma-dev libncurses5-dev libpng-dev libreadline-dev libsqlite3-dev \
        libssl-dev libxml2-dev libxmlsec1-dev libxslt-dev llvm locales make nano nodejs pkg-config \
        tk-dev tmux tzdata unixodbc-dev wget xz-utils zlib1g-dev > /dev/null && apt-get clean

ENV PYENV_ROOT /opt/.pyenv
RUN curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
ENV PATH /opt/.pyenv/shims:/opt/.pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN pyenv install 3.7.7
RUN pyenv global 3.7.7

RUN pip  install -U pip

RUN cd / && git clone https://github.com/schokoro/AlpacaTag.git src
RUN pip install -r /src/requirements.txt > /dev/null && \
        python -c "import shutil ; shutil.rmtree('/root/.cache')"
RUN python -m spacy download en

RUN cd /src/alpaca_server/ && python -m pip install .
RUN cd /src/alpaca_client/ && python -m pip install .

RUN cd /src/annotation/AlpacaTag/server && npm install  -g npm && npm audit fix --force && npm run build && cd .. && python manage.py migrate
WORKDIR /src/annotation/AlpacaTag/server 
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "python", "manage.py", "runserver", "0.0.0.0:8000" ]
EXPOSE 8000
