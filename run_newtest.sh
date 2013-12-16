#!/bin/bash

source settings.sh
date
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
rm -Rf temp/solr
source ${rvm_path}/scripts/rvm
rvm use ${IMPORT_RUBY_VERSION}
${rvm_path}/rubies/${IMPORT_RUBY_VERSION}/bin/jruby -Ku -J-Xms${RUBY_MEMLOW} -J-Xmx${RUBY_MEMHIGH} import.rb shortdata
date
