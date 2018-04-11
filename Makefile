.PHONY: all clean deploy bundle setup run help test remote-deploy

# tomcat config
TOMCAT_VERSION=8.5.16
TOMCAT_PATH=$(shell tom path $(TOMCAT_VERSION))
TOM_BIN=tom
DEPLOYMENT_PATH=$(TOMCAT_PATH)/webapps/subway

# Ruby/JRuby config
JRUBY_VERSION=9.1.12.0
JRUBY_JAR_NAME=jruby.jar
JRUBY_JAR=resources/jruby-$(JRUBY_VERSION)/lib/$(JRUBY_JAR_NAME)
RUBY=resources/jruby-$(JRUBY_VERSION)/bin/jruby
BUNDLER_VERSION=1.15.2
BUNDLER_PATH=resources/jruby-$(JRUBY_VERSION)/lib/ruby/gems/shared/gems/bundler-$(BUNDLER_VERSION)

PWD=$(shell pwd)

# rules
all: dist/subway.war

clean:
	rm -rf dist

$(BUNDLER_PATH):
	$(RUBY) -S gem install bundler --version $(BUNDLER_VERSION)

bundle: $(BUNDLER_PATH)
	$(RUBY) -S bundle install

dist/subway.war:
	@mkdir -p dist
	$(RUBY) -S warble executable war
	mv subway.war dist/

$(TOMCAT_PATH)/lib/$(JRUBY_JAR_NAME):
	cp $(JRUBY_JAR) $(TOMCAT_PATH)/lib

deploy: dist/subway.war $(TOMCAT_PATH)/lib/$(JRUBY_JAR_NAME)
	$(TOM_BIN) deploy $(TOMCAT_VERSION) dist/subway.war

undeploy:
	$(TOM_BIN) remove $(TOMCAT_VERSION) subway

remote-deploy: dist/subway.war
	scp dist/subway.war oracle@cidev01:~/downloads
	ssh oracle@cidev01 "bin/tom deploy ~/downloads/subway.war"	

$(TOMCAT_PATH):
	$(TOM_BIN) install $(TOMCAT_VERSION)

console:
	$(RUBY) -S pry -r ./app/subway.rb

server:
	$(RUBY) -S rackup

prodserver:
	$(RUBY) -S rackup -E production

setup: $(TOMCAT_PATH) bundle

dbbackup:
	cp $(DEPLOYMENT_PATH)/WEB-INF/db/subway.db db/subway.db

test:
	$(RUBY) resources/scripts/test.rb

testserver:
	$(RUBY) resources/scripts/test_server.rb

help:
	@echo Subway Makefile
	@echo
	@echo Rules:
	@echo     help - display this message
	@echo      all - build WAR file in 'dist' directory
	@echo    clean - remove 'dist' directory
	@echo   server - run application on a local JRuby based web server
	@echo  console - open console with application environment loaded
	@echo   deploy - deploy application to your local Tomcat installation
	@echo undeploy - remove application from your local Tomcat installation
	@echo    setup - development envionment including JRuby dependencies and Tomcat installation
