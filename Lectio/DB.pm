package Lectio::DB;

use DBI;
use Lectio::Config;
use Carp qw(croak);
use strict;

my $dbh;

=head1 NAME

Lectio::DB

=head1 SYNOPSIS

	use Lectio::DB;

	my $dbh = Lectio::DB->dbh();
	my $id = Lectio::DB->nextID();

=head1 DESCRIPTION

This package connects to a Lectio database and returns the database handle.

=head1 METHODS

=head2 dbh()

Returns database handle to Lectio.

=head1 AUTHOR

Robert J. Fox <rfox2@nd.edu>

=cut

sub dbh {

	if ($dbh) {
		return $dbh;
	}

	$dbh = DBI->connect($Lectio::Config::DATA_SOURCE, $Lectio::Config::USERNAME, $Lectio::Config::PASSWORD) || croak('Can\'t connect to database.');
	
	return $dbh;

}

sub nextID {

	my $self = shift;
	my $dbh = dbh();

	my $id = $dbh->selectrow_array('SELECT id FROM sequence');

	unless ($id) {
		# if not initialized, initialize sequence
		$dbh->do('INSERT INTO sequence (id) VALUES (1)');
	} else {
		$dbh->do('UPDATE sequence SET id = id + 1');
	}

	$id = $dbh->selectrow_array('SELECT id FROM sequence');

	if ($id) {
		return $id;
	} else { # there was a problem
		return;
	}
}

1;
