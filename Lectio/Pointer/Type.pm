package Lectio::Pointer::Type;

use Lectio::DB;
use Carp;
use strict;

=head1 NAME

Lectio::Pointer::Type

=head1 SYNOPSIS

	# use the module
	use Lectio::Pointer::Type;

	# create a pointer type object
	my $pointer_type = Lectio::Pointer::Type->new();

	# fill in attributes
	$pointer_type->pointer_type_name('JPG Primary');
	$pointer_type->pointer_type_description('This is a full sized image a page of a book.');
	$pointer_type->pointer_type_path('/local/images/full_sized/');

	# commit the pointer type
	$pointer_type->commit();

	# delete the pointer type
	$pointer_type->delete();

=head1 DESCRIPTION

This module is a child module for Pointer.pm which allows for the creation and manipulation of pointer types. Pointer types are labels and descriptions for various kinds of pointers which are utilized by Lection selections. The types correspond to various formats of digitized content. For example, a pointer could refer to a PDF file or a high resolution JPEG image. The pointer type also supplies information regarding the path to a given pointer object on the local operating system. It is assumed that digitized objects of a similar sort will be stored together. A pointer my only have one corresponding pointer type.

=head1 METHODS

This section outlines the various methods available in this module.

=head2 new()

This method can be used either to retrieve a pre-existing pointer type object, or create a new empty pointer type object. A pre-existing pointer object can be created by supplying the method a pointer type id or pointer type name.

	# create a new pointer type object
	my $pointer_type = Lectio::Pointer::Type->new();

	# create a previously stored object
	my $pointer_type = Lectio::Pointer::Type->new(id => $pointer_type_id);
	my $pointer_type = Lectio::Pointer::Type->new(name => 'JPEG Large');

=head2 pointer_type_id()

Use this method to retrieve the unique id for this pointer type. The method can only retrieve the id, it cannot set the id.

	# get the id of the current pointer type
	my $pointer_type_id = $pointer_type->pointer_type_id();

=head2 pointer_type_name()

Use this method to get or set the pointer type name for this object. The pointer type name should be meaningful in that it describes a specific type of digital object for functionality purposes. The name should also be unique among the types currently in use.

	# set the pointer type name
	$pointer_type->pointer_type_name('JPEG Full Size');

	# get the pointer type name
	my $pointer_type_name = $pointer_type->ponter_type_name();

=head2 pointer_type_description()

This method sets and retrieves a basic description of the purpose of this particular pointer type. This should more fully explain the purpose of the current pointer type.

	# set the pointer type description
	$pointer_type->pointer_type_description('This size of image is useful for viewing a digital monograph page for reading purposes or examining minute details such as page illuminations');

	# get the pointer type description
	my $pointer_type_description = $pointer_type->pointer_type_description();

=head2 pointer_type_path()

Use this method to set or get the pointer type path. Alway use trailing slashes.

	# set the pointer type path
	$pointer_type->pointer_type_path('/local/images/full/');

	# get the pointer type path
	my $pointer_path = $pointer_type->pointer_type_path();

=head2 commit()

Use this method to save the current pointer type object to the database.

	# commit the pointer type
	$pointer_type->commit();

=head2 delete()

Use this method to remove the current pointer type from the database.

	# delete the current pointer type
	$pointer_type->delete();

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
			croak "The id passed as input to the new method must be an integer: id = $opts{id} ";
		}

		# get a handle
		my $dbh = Lectio::DB->dbh();

		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM pointer_type WHERE pointer_type_id = ?', undef, $opts{id});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}
	} elsif ($opts{name}) {
	
		# get a handle
		my $dbh = Lectio::DB->dbh();

		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM pointer_type WHERE pointer_type_name = ?', undef, $opts{name});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}
	}

	# return the object
	return bless ($self, $class);

}

sub pointer_type_id {

	my $self = shift;
	return $self->{pointer_type_id};

}

sub pointer_type_name {

	my ($self, $pointer_type_name) = @_;

	if ($pointer_type_name) { $self->{pointer_type_name} = $pointer_type_name }

	return $self->{pointer_type_name};

}

sub pointer_type_description {

	my ($self, $pointer_type_description) = @_;

	if ($pointer_type_description) { $self->{pointer_type_description} = $pointer_type_description }

	return $self->{pointer_type_description};

}

sub pointer_type_path {

	my ($self, $pointer_type_path) = @_;

	if ($pointer_type_path) { $self->{pointer_type_path} = $pointer_type_path }

	return $self->{pointer_type_path};

}

sub commit {

	my $self = shift;

	my $dbh = Lectio::DB->dbh();

	# see if the object has an id
	if ($self->pointer_type_id()) {

		# update the existing selection
		my $return = $dbh->do('UPDATE pointer_type SET pointer_type_name = ?, pointer_type_description = ?, pointer_type_path = ? WHERE pointer_type_id = ?', undef, $self->pointer_type_name(), $self->pointer_type_description(), $self->pointer_type_path(), $self->pointer_type_id());

		if ($return > 1 || $return eq undef) { croak "Pointer type update in commit() failed. $return records were updated." }

	} else {

		# get a new sequence
		my $id = Lectio::DB->nextID();

		# create a new record
		my $return = $dbh->do('INSERT INTO pointer_type (pointer_type_id, pointer_type_name, pointer_type_description, pointer_type_path) VALUES (?, ?, ?, ?)', undef, $id, $self->pointer_type_name(), $self->pointer_type_description(), $self->pointer_type_path());
		if ($return > 1 || $return eq undef) { croak 'Pointer type commit() failed' }

		$self->{pointer_type_id} = $id;

	}

	return 1;

}

sub delete {

	my $self = shift;

	return 0 unless $self->{pointer_type_id};

	my $dbh = Lectio::DB->dbh();
	my $rv = $dbh->do('DELETE FROM pointer_type WHERE pointer_type_id = ?', undef, $self->{pointer_type_id});
	if ($rv != 1) { croak ("Delete failed. Deleted $rv records.") }

	return 1;

}

1;
