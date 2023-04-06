package Lectio::Author;

use Lectio::DB;
use Carp;
use strict;

=head1 NAME

Lectio::Author

=head1 SYNOPSIS

	# use the module
	use Lectio::Author;

	# create an author object
	my $author = Lectio::Author->new();

	# establish attributes
	$author->author_name('Christoph Clavius');
	$author->author_id();
	$author->author_description('Christoph Clavius is a 16th century Jesuit mathematician.');

	# commit the author
	$author->commit();

	# add selection to author
	$author->related_selection(action => 'add', selection => 245);

	# delete selection from author
	$author->related_selection(action => 'delete', selection => 245);

	# get all selections for author
	my @selection_ids = $author->related_selection(action => 'get_all');

	# delete author
	$author->delete()

=head1 DESCRIPTION

This module is repsonsible for the manipulation of author objects in a Lectio database. An author can be related to many, if not all, selections in a given collection. A selection may also be related to many authors. An author in this context is considered the person or organization primarily responsible for the content of the selection. Editors should not be considered.

=head1 METHODS

This section outlines the various methods available in this module.

=head2 new()

Use this method to create a author object. Called with no options, this method creates an empty object. Called with an author id, this method will create an object which relates to a specific author populated with metadata from the underlying database.

	# create a new author object
	my $author = Lectio::Author->new();

	# create a specific author object
	my $author = Lectio::Author->new(id => 25);

=head2 author_id()

This method returns an integer representing the database key of the currently created author object.

	# get the id of the current author object
	my $auth_id = $author->author_id();

The id attribute cannot be set.

=head2 author_name()

As stated previously, an author should be the primarily responsible party for a given selection. The name should be unique for a given collection. This method can either set or get the author name.

	# set the author name
	$author->author_name('Christoph Clavius');

	# get the author name
	my $author_name = $author->author_name();

=head2 author_description()

The description should provide material which is useful for the scholar studying a given collection. This method can be used to set or get the descriptive text for an author.

	# set the author description()
	$author->author_description('Christoph Clavius was a 16th century Jesuit scholar.');

	# get the author description()
	my $description = $author->author_description();

=head2 commit()

The commit method simply saves the current author object to the database.

	# commit the author
	$author->commit();

=head2 related_selection()

This method can add, delete and retrieve the entire list of selection object ids related to this author. Selection ids need to be added or deleted individually. The action parameter determines what action will be taken by the method. If an add is called for, then the selection parameter must be submitted along with an appropriate selection id. This is also true for the delete action. A list of selection ids will be returned when the 'get all' action is called.

	# add a selection to this author
	$author->related_selection(action => 'add', selection => 245);

	# get all selection ids related to this author
	my @selection_ids = $author->related_selection(action => 'get_all');

	# delete a selection association from this author
	$author->related_selection(action => 'delete', selection => 245);

=head1 AUTHOR

	Robert J. Fox <rfox2@nd.edu>

=cut

sub new {

	my ($class, %opts) = @_;
	my $self           = {};

	# check for an id
	if ($opts{id}) {
		
		# check for valid input, an integer
		if ($opts{id} =~ /\D/) {
			# output an error and return nothing
			croak "The id passed as input to the new method must be an integer: id = $opts{id} ";
		}

		# get a handle
		my $dbh = Lectio::DB->dbh();

		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM author WHERE auth_id = ?', undef, $opts{id});
		
		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}

	} elsif ($opts{name}) {
	
		my $dbh = Lectio::DB->dbh();

		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM author WHERE auth_name = ?', undef, $opts{name});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}
	}

	# return the object
	return bless ($self, $class);

}

sub author_id {

	my $self = shift;
	return $self->{auth_id};

}

sub author_name {

	my ($self, $author_name) = @_;
	
	if ($author_name) { $self->{auth_name} = $author_name }

	return $self->{auth_name};
}

sub author_description {

	my ($self, $author_description) = @_;

	if ($author_description) { $self->{auth_description} = $author_description }

	return $self->{auth_description};

}

sub commit {

	my $self = shift;

	unless ($self->author_name()) {
		croak "Missing author name.";
	}

	my $dbh = Lectio::DB->dbh();

	# see if the object has an id
	if ($self->author_id()) {
		
		# update the existing author
		my $return = $dbh->do('UPDATE author SET auth_name = ?, auth_description = ? WHERE auth_id = ?', undef, $self->author_name(), $self->author_description(), $self->author_id());

		my $error = $dbh->errstr;

		if ($return > 1 || $return eq undef) { croak "Author update in commit() failed. $return records were updated. Database returned error $error" }

	} else {

		# get a new sequence
		my $id = Lectio::DB->nextID();

		# create a new record
		my $return = $dbh->do('INSERT INTO author (auth_id, auth_name, auth_description) VALUES (?, ?, ?)', undef, $id, $self->author_name(), $self->author_description());
		my $error = $dbh->errstr;
		if ($return > 1 || $return eq undef) { croak "Author commit() failed. Database returned error $error"; }
		$self->{auth_id} = $id;

	}

	return 1;

}

sub related_selection {

	my ($self, %opts) = @_;

	my $dbh = Lectio::DB->dbh();
	
	if ($opts{action} eq 'add') {
		unless ($opts{selection} =~ /\d/) {
			croak "Selection parameter not submitted or parameter data in incorrect format.";
		}

		my $return = $dbh->do('INSERT INTO selection_authorship (selection_id, auth_id) VALUES (?, ?)', undef, $opts{selection}, $self->author_id());
		my $error = $dbh->errstr;
		if ($return > 1 || $return eq undef) { croak "related_selection() update failed for Author. Database returned error: $error"; }

		return '1';

	} elsif ($opts{action} eq 'delete') {

		unless ($opts{selection} =~ /\d/) {
			croak "Selection parameter not submitted or parameter data in incorrect format.";
		}

		my $return = $dbh->do('DELETE FROM selection_authorship WHERE selection_id = ? AND auth_id = ?', undef, $opts{selection}, $self->author_id());
		my $error = $dbh->errstr;
		if ($return > 1 || $return eq undef) { croak "related_selection() delete failed for Author. Database returned error: $error"; }

	} elsif ($opts{action} eq 'get_all') {
	
		my $return = $dbh->selectcol_arrayref('SELECT selection_id FROM selection_authorship WHERE auth_id = ?', undef, $self->author_id());
		if (scalar(@{$return})) {
			return @{$return};
		} else {
			return;
		}

	}

}

sub delete {

	my $self = shift;

	return 0 unless $self->author_id();

	my $dbh = Lectio::DB->dbh();
	my $rv = $dbh->do('DELETE FROM selection_authorship WHERE auth_id = ?', undef, $self->author_id());
	my $rv = $dbh->do('DELETE FROM author WHERE auth_id = ?', undef, $self->author_id());
	my $error = $dbh->errstr;
	if ($rv != 1) { croak ("Delete author failed. Deleted $rv records. Database returned error: $error") }

	return 1;

}

1;
