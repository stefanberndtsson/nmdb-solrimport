#!/bin/bash

source settings.sh
date
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
mv temp/solr temp/solr.old
rm -Rf temp/solr.old* &
psql nmdb < dump_from_sql.sql
source ${rvm_path}/scripts/rvm
rvm use ${IMPORT_RUBY_VERSION}
${rvm_path}/rubies/${IMPORT_RUBY_VERSION}/bin/jruby -Ku -J-Dcompile.fastest=true -J-Dcompile.fastsend=true -J-Dcompile.fastMasgn=true -J-Dcompile.invokedynamic=true -J-Dinvokedynamic.all=true --server -J-Xms${RUBY_MEMLOW} -J-Xmx${RUBY_MEMHIGH} import.rb data
date
