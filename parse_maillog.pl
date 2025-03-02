#!/usr/bin/env perl

use strict;
use warnings;

use Carp qw(croak);
use DBI;

# Должно браться из конфига
my $db_host = $ENV{MYSQL_HOST}     || 'localhost';
my $db_name = $ENV{MYSQL_DATABASE} || 'mariadb';
my $db_user = $ENV{MYSQL_USER}     || 'mariadb';
my $db_pass = $ENV{MYSQL_PASSWORD} || 'mariadb';

my $dbh = DBI->connect( "DBI:mysql:database=$db_name;host=$db_host",
    $db_user, $db_pass, { RaiseError => 1, AutoCommit => 1 } );

use constant MAX_BIND_PARAMS => 65_535;  # Найдено на StackOverflow, не проверял
use constant NUM_MESSAGE_COLUMNS => 4;    # Количество колонок в таблице message
use constant NUM_LOG_COLUMNS     => 4;    # Количество колонок в таблице log

my $message_batch_size =
  MAX_BIND_PARAMS - MAX_BIND_PARAMS % NUM_MESSAGE_COLUMNS;

my $log_batch_size = MAX_BIND_PARAMS - MAX_BIND_PARAMS % NUM_LOG_COLUMNS;

my @message_records;
my @log_records;

while ( my $line = <> ) {
    chomp $line;

    if ( $line !~
/^(?<created>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (?<str>(?<int_id>\S{16})(?: (?<flag><=|=>|->|\*\*|==) (?<address>\S+))? .*?)$/
      )
    {
        warn "Can't parse log line (skipping it): $line";
        next;
    }

    my $created = $+{created};
    my $int_id  = $+{int_id};
    my $flag    = $+{flag} || '';
    my $address = $+{address};
    my $str     = $+{str};

    # Special cases
    if ( defined $address ) {
        if ( $address eq '<>' ) {
            $address = '';
        }
        elsif ($address eq ':blackhole:'
            && $str =~ / :blackhole: <(\S+)> / )
        {
            $address = $1;
        }

        $address = lc $address;
    }

    if ( $flag eq '<=' && $str =~ / id=(\S+)/ ) {
        my $id = $1;
        push @message_records, ( $created, $id, $int_id, $str );

        insert_message_records( splice @message_records,
            0, $message_batch_size )
          if @message_records >= $message_batch_size;
    }

    push @log_records, ( $created, $int_id, $str, $address );

    insert_log_records( splice @log_records, 0, $log_batch_size )
      if @log_records >= $log_batch_size;
}

insert_message_records(@message_records)
  if @message_records > 0;

insert_log_records(@log_records)
  if @log_records > 0;

exit 0;

###

sub insert_message_records {
    my @bind_params = @_;

    my $num_rows = @bind_params / NUM_MESSAGE_COLUMNS;

    my $sth =
      prepare_insert_statement( 'message', $num_rows,
        qw( created id int_id str ) );

    $sth->execute(@bind_params);
}

sub insert_log_records {
    my @bind_params = @_;

    my $num_rows = @bind_params / NUM_LOG_COLUMNS;

    my $sth =
      prepare_insert_statement( 'log', $num_rows,
        qw(created int_id str address) );

    $sth->execute(@bind_params);
}

sub prepare_insert_statement {
    my ( $table, $num_rows, @columns ) = @_;

    croak "Number of bind params exceeds MAX_BIND_PARAMS"
      if $num_rows * scalar(@columns) > MAX_BIND_PARAMS;

    my $sql_statement =
      "INSERT INTO $table (" . ( join ',', @columns ) . ") VALUES\n";

    $sql_statement .= join ",\n", map {
        "(" . ( join ',', map { '?' } @columns ) . ")"
    } 1 .. $num_rows;

    $sql_statement .= ";\n";

    return $dbh->prepare($sql_statement);
}
