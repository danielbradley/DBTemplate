project=$(shell cat ../PROJECT)
target=_sql
osname=$(shell uname)
extract=../libexec/Extract/bin/$(osname)/extract

all: dir spgen tables functions views fixed_data stored_procedures final events test testing check

dir:
	mkdir -p _sql

spgen:
	$(extract) -p "spgen"                     mt/*.txt >  _sql/tmp-$(project)-spgen.sql

tables:
	$(extract) -p "tables"                    mt/*.txt >  _sql/tmp-$(project)-schema.sql

functions:
	$(extract) -p "fn_groups"                 mt/*.txt >> _sql/tmp-$(project)-schema.sql

views:
	$(extract) -p "views_groups"              mt/*.txt >> _sql/tmp-$(project)-schema.sql 

fixed_data:
	$(extract) -p "fixed_data_notifications"  mt/*.txt >> _sql/tmp-$(project)-schema.sql

stored_procedures:
	$(extract) -p "sp_users"                  mt/*.txt >  _sql/tmp-$(project)-sp.sql
	$(extract) -p "sp_groups"                 mt/*.txt >> _sql/tmp-$(project)-sp.sql

final:
	$(extract) -p "final"                     mt/*.txt >> _sql/tmp-$(project)-sp.sql

test:
	$(extract) -p "test"                      mt/*.txt >> _sql/tmp-$(project)-sp.sql

events:
	echo ""                                            >  _sql/tmp-$(project)-events.sql 
	$(extract) -p "events"                    mt/*.txt >> _sql/tmp-$(project)-events.sql

testing:
	echo ""                                            >  _sql/tmp-$(project)-testing.sql 
	$(extract) -p "sp_testing_common"         mt/*.txt >> _sql/tmp-$(project)-testing.sql

check:
	file _sql/tmp-$(project)-spgen.sql
	file _sql/tmp-$(project)-schema.sql
	file _sql/tmp-$(project)-sp.sql
	file _sql/tmp-$(project)-events.sql
	file _sql/tmp-$(project)-testing.sql

clean:
	rm -rf _sql
