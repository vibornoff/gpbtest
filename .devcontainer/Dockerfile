FROM mcr.microsoft.com/devcontainers/base:debian

RUN sudo apt update \
    && (yes | sudo apt install perl-doc libmodule-build-perl libmodule-install-perl \
                               libanyevent-perl libclass-refresh-perl libcompiler-lexer-perl libdata-dump-perl libio-aio-perl \
                               libjson-perl libmoose-perl libpadwalker-perl libscalar-list-utils-perl libcoro-perl perltidy \
                               libdbi-perl libdbd-mysql-perl mariadb-client libmojolicious-perl) \
    && (yes | sudo cpan Perl::LanguageServer)
