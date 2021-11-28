arch := $(shell uname)

all: extract maxtext mysqlscripts

extract: Extract/bin/$(arch)/extract

Extract/bin/$(arch)/extract: Extract
	make -C Extract

Extract:
	git clone https://github.com/danielbradley/Extract.git

maxtext: MaxText/maxtext/bin/maxtext

MaxText/maxtext/bin/maxtext: MaxText
	export OSTYPE
	make -C MaxText/maxtext all

MaxText:
	git clone https://github.com/danielbradley/MaxText.git

mysqlscripts: ../mysql.sh

../mysql.sh: MySQLScripts
	make -C MySQLScripts install

MySQLScripts:
	git clone https://github.com/danielbradley/MySQLScripts.git

clean:
	rm -rf Extract MaxText MySQLScripts
