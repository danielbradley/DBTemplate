prefix=$(shell cat PROJECT)-
version=$(shell cat VERSION)
ostype=$(shell uname)
extract=libexec/Extract/bin/$(ostype)/extract
max2html=libexec/MaxText/maxtext/bin/$(ostype)/max2html

now=$(shell date "+%Y-%m-%dT%H:%M:%S")
baseschema="./dep/BaseSchema/baseschema-4.v.sql"
spgen="./share/sql/${version}/${prefix}spgen.sql"
schema="./share/sql/${version}/${prefix}schema.sql"
sp="./share/sql/${version}/${prefix}sp.sql"
events="./share/sql/${version}/${prefix}events.sql"

all: $(extract) make copy

$(extract):
	make -C libexec all

make:
	make -C source

copy:
	mkdir -p share/sql/$(version)
	cp source/_sql/tmp-$(prefix)spgen.sql    share/sql/$(version)/$(prefix)spgen.sql
	cp source/_sql/tmp-$(prefix)schema.sql   share/sql/$(version)/$(prefix)schema.sql
	cp source/_sql/tmp-$(prefix)sp.sql       share/sql/$(version)/$(prefix)sp.sql
	cp source/_sql/tmp-$(prefix)events.sql   share/sql/$(version)/$(prefix)events.sql
	cp source/_sql/tmp-$(prefix)testing.sql  share/sql/$(version)/$(prefix)testing.sql

xattr:
	xattr -rd com.apple.metadata:kMDLabel_2lrcdw32xqyl7c4b3fukng4qfi source/mt 

install: all
	mkdir -p _install/$(version)
	rm    -f _install/$(version)/*.sql
	cat $(baseschema) $(spgen) $(schema) $(sp) $(events) > _install/$(version)/$(prefix)$(version)-$(now).sql

doc:
	make -C documentation

req:
	make -C requirements

clean:
	make -C source  clean
	make -C libexec clean
	rm -f backup.sh install.sh mysql.sh
