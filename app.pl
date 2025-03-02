#!/usr/bin/env perl

use DBI;
use Mojolicious::Lite -signatures;

# Должно браться из конфига
my $db_host = $ENV{MYSQL_HOST}     || 'localhost';
my $db_name = $ENV{MYSQL_DATABASE} || 'mariadb';
my $db_user = $ENV{MYSQL_USER}     || 'mariadb';
my $db_pass = $ENV{MYSQL_PASSWORD} || 'mariadb';

my $dbh = DBI->connect( "DBI:mysql:database=$db_name;host=$db_host",
    $db_user, $db_pass, { RaiseError => 1, AutoCommit => 1 } );

get '/' => sub ($c) {
    $c->render( template => 'index', maillog => {} );
};

post '/' => sub ($c) {
    my $v = $c->validation;
    return $c->render( text => 'Bad CSRF token!', status => 403 )
      if $v->csrf_protect->has_error('csrf_token');

    my $address = $c->param('address');
    if ( !length $address ) {
        $c->render( template => 'index', maillog => {} );
        return;
    }
    if ( length $address > 255 ) {
        $c->render( template => 'index', status => 400, maillog => {} );
        return;
    }

    my $results = query_maillog($address);

    my $more_than_100 = @$results > 100;
    pop @$results if $more_than_100;

    $c->render(
        template => 'index',
        maillog  => {
            more_than_100 => $more_than_100,
            results       => $results,
        },
    );
};

app->start;

sub query_maillog ($address) {
    my $results = $dbh->selectall_arrayref(
        "SELECT created, str FROM log WHERE address = ?
         ORDER BY 1 ASC, 2
         LIMIT 101",
        { Slice => {} },
        lc $address,
    );

    return $results;
}

__DATA__

@@ index.html.ep
% layout 'default';
% title 'GPBTEST';
%= form_for '' => ( method => 'POST' ) => begin
    %= csrf_field
    %= label_for address => 'Address'
    %= text_field 'address', id => 'address'
    %= submit_button
%= end
%if ( defined $maillog->{results} ){
    %if ( $maillog->{more_than_100} ){
        <p>Only showing the first 100 results</p>
    % } else {
        <p><%= scalar @{ $maillog->{results} } %> results</p>
    % }
    <hr />
    <pre>
    %for my $r ( @{ $maillog->{results} } ) {
%= $r->{created} . ' ' . $r->{str}
    % }
    </pre>
% }

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
