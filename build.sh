yum install wget
mkdir pandoc
wget -qO- https://github.com/jgm/pandoc/releases/download/2.18/pandoc-2.18-linux-amd64.tar.gz | \
   tar xvz --strip-components 2 -C ./pandoc
export PATH="./pandoc/bin:$PATH"

yarn run build

