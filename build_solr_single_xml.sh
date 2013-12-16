#!/bin/bash

source settings.sh
date
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

source ${rvm_path}/scripts/rvm
rvm use 1.9.3-p194

function do_files {
    for file in *"$1"/output.xml
    do
	if test -f "$file"
	then
	    echo "Sending ${file}..."

	    sort "$file" | ../../recode_solr.rb | curl -X POST --header "Content-Type:text/xml" -d @- 'http://localhost:8080/solr/core0/update?wt=' # >> /tmp/solr_update.log 2>&1
	fi
    done
}

echo '<?xml version="1.0" encoding="UTF-8"?><add>' > /tmp/addstart.xml
echo '</add>' > /tmp/addend.xml
echo '<doc>' > /tmp/docstart.xml
echo '</doc>' > /tmp/docend.xml

echo '<?xml version="1.0" encoding="UTF-8"?><delete><query>*:*</query></delete>' | curl -X POST --header "Content-Type:text/xml" -d @- 'http://localhost:8080/solr/core0/update?wt=' > /tmp/solr_update.log 2>&1
echo '<?xml version="1.0" encoding="UTF-8"?><commit/>' | curl -X POST --header "Content-Type:text/xml" -d @- 'http://localhost:8080/solr/core0/update?wt=' >> /tmp/solr_update.log 2>&1
echo '<?xml version="1.0" encoding="UTF-8"?><optimize/>' | curl -X POST --header "Content-Type:text/xml" -d @- 'http://localhost:8080/solr/core0/update?wt=' >> /tmp/solr_update.log 2>&1

cd temp/solr
do_files 0
do_files 1
do_files 2
do_files 3
do_files 4
do_files 5
do_files 6
do_files 7
do_files 8
do_files 9

echo '<?xml version="1.0" encoding="UTF-8"?><commit/>' | time curl -X POST --header "Content-Type:text/xml" -d @- 'http://localhost:8080/solr/core0/update?wt=' >> /tmp/solr_update.log 2>&1
echo '<?xml version="1.0" encoding="UTF-8"?><optimize/>' | time curl -X POST --header "Content-Type:text/xml" -d @- 'http://localhost:8080/solr/core0/update?wt=' >> /tmp/solr_update.log 2>&1
