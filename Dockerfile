FROM debian:bullseye-slim AS binary
LABEL description="cosigt"
LABEL base_image="debian:bullseye-slim"
LABEL software="cosigt"
LABEL about.home="https://github.com/davidebolo1993/cosigt"
LABEL about.license="GPLv3"

ARG DEBIAN_FRONTEND=noninteractive
#install basic libraries and python

WORKDIR /opt

RUN apt-get update

RUN apt-get -y install \
	build-essential \
	software-properties-common \
	bash \
	wget \
	curl \
	git \
	bzip2 \
	libbz2-dev \
	libgsl-dev \
	zlib1g \
	zlib1g-dev \
	liblzma-dev \
	libssl-dev \
	libncurses5-dev \
	libz-dev \
	python3-dev \
	python3-pip \ 
	libjemalloc-dev \
	cmake \
	make \
	g++ \
	libhts-dev \
	libzstd-dev \
	autoconf \
	libatomic-ops-dev \
	pkg-config \
	libomp5 \
	libomp-dev \
	libssl-dev \
	pkg-config \
	zip \
	unzip

#install golang
RUN add-apt-repository ppa:longsleep/golang-backports

RUN apt-get -y install golang-go \
	&& apt-get -y clean all \
	&& apt-get -y purge \
	&& rm -rf /var/cache \
	&& rm -rf /var/lib/apt/lists/*

#install rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

#and update
RUN rustup update
RUN cargo install --locked maturin

#install python libraries here
#RUN pip3 install ...

#ln python to python3 -not used right now but, who knows?
RUN ln -s /usr/bin/python3 /usr/bin/python

##install samtools
RUN wget https://github.com/samtools/samtools/releases/download/1.21/samtools-1.21.tar.bz2 \
	&& tar -jxvf samtools-1.21.tar.bz2 \
	&& rm samtools-1.21.tar.bz2 \
	&& cd samtools-1.21 \
	&& ./configure \
	&& make \
	&& cp samtools /opt/samtools \
	&& cd .. \
	&& rm -rf samtools-1.21

##install bwa-mem
RUN git clone https://github.com/lh3/bwa.git \
	&& cd bwa \
	&& git checkout 79b230de48c74156f9d3c26795a360fc5a2d5d3b \
	&& make \
	&& cp bwa ../bwa-tmp \
	&& cd .. \
	&& rm -rf bwa \
	&& mv bwa-tmp bwa

##install bwa-mem2
RUN wget https://github.com/bwa-mem2/bwa-mem2/releases/download/v2.2.1/bwa-mem2-2.2.1_x64-linux.tar.bz2 \
	&& tar -jxvf bwa-mem2-2.2.1_x64-linux.tar.bz2 \
	&& rm bwa-mem2-2.2.1_x64-linux.tar.bz2

ENV PATH /opt/bwa-mem2-2.2.1_x64-linux:$PATH

##install minimap2
RUN wget https://github.com/lh3/minimap2/releases/download/v2.28/minimap2-2.28_x64-linux.tar.bz2 \
	&& tar -jxvf minimap2-2.28_x64-linux.tar.bz2 \
	&& rm minimap2-2.28_x64-linux.tar.bz2

ENV PATH /opt/minimap2-2.28_x64-linux:$PATH

##install bedtools
RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.31.0/bedtools.static \
	&& chmod +x bedtools.static \
	&& mv bedtools.static bedtools

## install megadepth
RUN wget https://github.com/ChristopherWilks/megadepth/releases/download/1.2.0/megadepth \
	&& chmod +x megadepth

##install wfmash
RUN wget https://github.com/waveygang/wfmash/releases/download/v0.14.0/wfmash-v0.14.0.tar.gz \
	&& tar -xvzf wfmash-v0.14.0.tar.gz \
	&& rm wfmash-v0.14.0.tar.gz \
	&& cd wfmash-v0.14.0 \
	&& cmake -H. -Bbuild \
	&& cmake --build build -- -j 8 \
	&& cd ..

ENV PATH /opt/wfmash-v0.14.0/build/bin:$PATH

##install gafpack
RUN git clone https://github.com/pangenome/gafpack.git \
	&& cd gafpack \
	&& git checkout 6a0b7940d0ca4b552f5f80b3d1668ed0312080ad \
	&& cargo install --force --path . \
	&& cp target/release/gafpack ../gafpack-tmp \
	&& cd .. \
	&& rm -rf gafpack \
	&& mv gafpack-tmp gafpack

##install gfainject
RUN git clone https://github.com/AndreaGuarracino/gfainject \
	&& cd gfainject \
	&& git checkout b32b2a03b90d4c9ae935737b3bd7bd86ca8a2d78 \
	&& cargo install --force --path . \
	&& cp target/release/gfainject ../gfainject-tmp \
	&& cd .. \
	&& rm -rf gfainject \
	&& mv gfainject-tmp gfainject

##install impg
RUN git clone https://github.com/pangenome/impg \
	&& cd impg \
	&& git checkout 37b18e18123d92fa5fa824a4e15d8aa7cad3b6db \
	&& cargo install --force --path . \
	&& cp target/release/impg ../impg-tmp \
	&& cd .. \
	&& rm -rf impg \
	&& mv impg-tmp impg

##install cosigt
RUN git clone https://github.com/davidebolo1993/cosigt.git \
	&& cd cosigt \
	&& go mod init cosigt \
	&& go mod tidy \
	&& go build cosigt \
	&& cp cosigt ../cosigt-tmp \
	&& cd .. \
	&& rm -rf cosigt \
	&& mv cosigt-tmp cosigt

ENV PATH /opt:$PATH

#R and R libs w/conda - adding should be easier

RUN curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -p /miniconda -b
RUN rm Miniconda3-latest-Linux-x86_64.sh
ENV PATH=/miniconda/bin:${PATH}
RUN conda update -y conda
RUN conda create -y -n renv -c conda-forge -c bioconda \
	r-base \
	r-data.table=1.15.4 \
	r-rjson=0.2.23 \
	r-reshape2=1.4.4 \
	r-nbclust=3.0.1 \
	r-ggplot2=3.5.1 \
	r-dendextend=1.18.1 \
	r-gggenes=0.5.1 \
	bioconductor-rtracklayer=1.62.0 \
	r-randomcolor=1.1.0.1
RUN echo "source activate renv" > ~/.bashrc
ENV PATH /miniconda/envs/renv/bin:$PATH