package Lectio::Collection;

use Lectio::DB;
use Carp;
use strict;

=head1 NAME

Lectio::Collection

=head1 SYNOPSIS

	# use the module
	use Lectio::Collection;

	# create a collection object
	my $collection = Lectio::Collection->new();

	# fill in some attributes
	$collection->coll_name('Opera Mathematica');
	$collection->coll_description('These are the collected works of Christoph Clavius.');

	# find out how many selections are associated with this collection
	my $selection_count = $collection->selection_count();

	# save the collection to the database
	$collection->commit();

	# delete this collection entry
	$collection->delete();

=head1 DESCRIPTION

This module will allow the simple manipulation of metadata associated with a specific Lection collection. A collection is the parent organizing principle for an entire group of selection objects, which may include such selection objects as books, chapters and pages. When a collection is deleted, it is possible (at this point) that all of it's selection objects will be orphaned in the database. A parameter can be submitted to the delete() parameter which will remove all vestiges of a collection, including all of it's child selection objects. Therefore, care should be taken when using the delete() method.

=head1 METHODS

This section outlines the various methods available in this module.

=head2 new()

Use this method to create a collection object. Called with no options, this method creates an empty object. Called with a collection id, this method will create an object which relates to a specific collection with metadata from the underlying database.

	# create a new collection object
	my $collection = Lectio::Collection->new();

	# create a pre-existing collection object
	my $collection = Lectio::Collection->new(id => 25);

=head2 collection_id()

This method will only return the database id for the current collection object. The id cannot be set using this method.

	# get id for collection object
	my $coll_id = $collection->collection_id();

=head2 coll_name()

Use this method to set or get the name of the collection object.

	# get the collection name
	my $coll_name = $collection->coll_name();

	# set the collection name
	$collection->coll_name('Opera Mathematica');

=head2 coll_description()

The description for the collection should contain unique information about this collection such as the significance of the collection, it's relevance to a particular line of research, historical information, size of the collection, it's primary format, and perhaps holdings information. Use this method to set or get the collection description.

	# get the collection description
	my $coll_description = $collection->coll_description();

	# set the collection description
	$collection->coll_description('These are the collected works of Christoph Clavius, S.J.');

=head2 selection_count()

Use this method to find out precisely how many selections are currently associated with this collection. This method does not accespt any input.

	# find out number of selections associaed with this collection
	my $selection_count = $collection->selection_count();

=head2 commit()

This method will commit the current collection object to the database. If a new object is being created, this method will increment the sequence id and create a new record in the database.

This method will return true on success.

	# commit the current collection object to the database
	$collection->commit();

=head2 delete()

Use this method with care. If no parameters are submitted, only the collection entry with it's metadata will be removed from the database. This has the possibility of orphaning many selection objects. However, if the purge parameter is submitted, all selection objects associated with this collection will be removed as well.

	# perform a simple collection metadata delete
	$collection->delete();

	# remove collection metadata along with all related selection objects
	$collection->delete(purge => '1');

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
		my $rv = $dbh->selectrow_hashref('SELECT * FROM collection WHERE coll_id = ?', undef, $opts{id});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}
	} elsif ($opts{name}) {

		my $dbh = Lectio::DB->dbh();

		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM collection WHERE coll_name = ?', undef, $opts{name});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}
	}

	# return the object
	return bless ($self, $class);

}

sub collection_id {

	my $self = shift;
	return $self->{coll_id};

}

sub coll_name {

	my ($self, $collection_name) = @_;

	if ($collection_name) { $self->{collection_name} = $collection_name }

	return $self->{collection_name};

}

sub coll_description {

	my ($self, $collection_description) = @_;

	if ($collection_description) { $self->{collection_description} = $collection_description }

	return $self->{collection_description};

}

sub selection_count {

	my $self = shift;

	my $dbh = Lectio::DB->dbh();
	my $rv = $dbh->selectcol_arrayref('SELECT selection_id FROM selection WHERE coll_id = ?', undef, $self->{coll_id});

	if (scalar(@{$rv}) >= 1) {
		return scalar(@{$rv});
	} else {
		return '0';
	}

}

sub commit {

	my $self = shift;

	my $dbh = Lectio::DB->dbh();

	# see if the object has an id
	if ($self->collection_id()) {

		# update the existing collection
		my $return = $dbh->do('UPDATE collection SET coll_name = ?, coll_description = ? WHERE coll_id = ?', undef, $self->coll_name(), $self->coll_description(), $self->collection_id());
		
		if ($return > 1 || $return eq undef) { croak "Collection update in commit() failed. $return records were updated." }

	} else {

		# get a new sequence
		my $id = Lectio::DB->nextID();

		# create a new record
		my $return = $dbh->do('INSERT INTO collection (coll_id, coll_name, coll_description) VALUES (?, ?, ?)', undef, $id, $self->coll_name(), $self->coll_description());
		
		if ($return > 1 || $return eq undef) { croak 'Collection commit() failed.'; }

		$self->{coll_id} = $id;
	}

	return 1;

}

sub delete {

	my ($self, %opts) = @_;

	return 0 unless $self->{coll_id};

	my $dbh = Lectio::DB->dbh();

	if ($opts{purge}) {

		my $selection_array = $dbh->selectcol_arrayref('SELECT selection_id FROM selection WHERE coll_id = ?', undef, $self->{coll_id});
		my @selection_ids = @{$selection_array};
		if (scalar(@selection_ids)) {
			foreach my $selection_id (@selection_ids) {
				my $selection = Lectio::Selection->new(id => $selection_id);
				$selection->delete();
			}
		}

		my $rv = $dbh->do('DELETE FROM collection WHERE coll_id = ?', undef, $self->{coll_id});
		if ($rv != 1) { croak ("Delete failed. Deleted $rv records.") }
		return 1;	

	} else {

		my $rv = $dbh->do('DELETE FROM collection WHERE coll_id = ?', undef, $self->{coll_id});
		if ($rv != 1) { croak ("Delete failed. Deleted $rv records.") }
		return 1;

	}


}

1;
