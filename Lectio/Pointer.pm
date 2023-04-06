package Lectio::Pointer;

use Lectio::DB;
use Lectio::Pointer::Type;
use Carp;
use strict;

=head1 NAME

Lectio::Pointer

=head1 SYNOPSIS

	# use the module
	use Lectio::Pointer;

	# create a selection object
	my $pointer = Lectio::Pointer->new();

	# establish attributes
	$pointer->pointer_type('123');
	$pointer->selection_id('456');
	$pointer->pointer('my_pic.jpg');

	# commit the pointer
	$pointer->commit()

	# delete a pointer
	$pointer->delete();

=head1 DESCRIPTION

This module allows for the creation and manipulation of pointer objects associated with a given selection from a Lection collection. The object contains identifiers which point to types and selection ids to which the pointer is related, as well as the pointer string itself. Pointer types can include virtually any digital type (which may be text, compressed image data, audio recordings, etc). A pointer is related to one and only one selection, but a selection may have multiple pointers associated with it (e.g. - a thumbnail JPEG image and a full size image of the same selection). The pointer itself is usually the name of the digital object (e.g. - 1_34_b_trin.jpg). The pointer type will contain other informatin necessary to locate the actual digital object.

=head1 METHODS

This section outlines the various methods available in this module.

=head2 new()

Use this method to create a pointer object. Called with no options, this method creates an empty object. Called with a pointer id, this method will create an object which corresponds to a specific pointer in the database. Called with a name, this method will return a list of pointer objects corresponding to that name. If called with the name parameter in a scalar context, this method will return the first matching value it finds. If called in a list context, the full list will be returned.

	# create a new pointer object
	my $pointer = Lectio::Pointer->new();

	# create an existing pointer
	my $pointer = Lection::Pointer->new(id => 234);
	my @pointers = Lection::Pointer->new(name => '1_2_3_small.jpg');

=head2 pointer_id()

This method returns an integer representing the database key of the currently created pointer object.

	# get id of current pointer object
	my $id = $pointer->pointer_id()

The id attribute cannot be set.

=head2 pointer_type()

Use this method to set or get the pointer type id for the current pointer object. A given pointer can only be related to one pointer type, but a pointer type can be used repeatedly. A pointer type represents the fundamental qualities of the pointer in hand. For example, a pointer may be a full size image of a selection or it may be a thumbnail image. The pointer type will not only indicate the type of pointer, but also path information to access the pointer digital object. Pointer types can be created, if the developer desires, but the business logic to handle multiple pointer types will be up to the institution that uses this Perl library.

	# set the pointer type
	$pointer->pointer_type('123');

	# retrieve the pointer type
	my $type_id = $pointer->pointer_type();

=head2 selection_id()

Use this method to set or get the parent selection id for this pointer. As stated previously, a selection may be related to several pointers representing possibly various formats of the same logical object (selection).

	# set the selection id
	$pointer->selection_id('678');

	# get the selection id
	my $selection_id = $pointer->selection_id();

=head2 pointer()

The pointer is simply a string which represents the name of a given digital object related to a selection. This method either sets or gets the string for this pointer.

	# set the pointer
	$pointer->pointer('1_3_6_trin.jpg');

	# get the pointer
	my $pointer_string = $pointer->pointer();

=head2 commit()

Use this method to save the current object to the database.

	# commit the pointer
	$pointer->commit()

=head2 delete()

This method will delete the current pointer object from the database.

	# delete this pointer
	$pointer->delete()

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
		my $rv = $dbh->selectrow_hashref('SELECT * FROM pointer WHERE pointer_id = ?', undef, $opts{id});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}

		# return the object
		return bless ($self, $class);

	} elsif ($opts{name}) {

		# get a handle
		my $dbh = Lectio::DB->dbh();

		my @full_pointer_list = ();

		my $pointer_array_ref = $dbh->selectall_hashref('SELECT * FROM pointer WHERE pointer = ?', 'pointer_id', undef, $opts{name});

		if (scalar(%{$pointer_array_ref})) {

			if (wantarray) {

				foreach my $pointer_ref_id (keys %{$pointer_array_ref}) {
					my %pointer_hash = %{$pointer_array_ref};
					my $pointer_ref = $pointer_hash{$pointer_ref_id};
					if (ref($pointer_ref) eq "HASH") {
						bless ($pointer_ref, $class);
						push(@full_pointer_list, $pointer_ref);
					}
				}

				return @full_pointer_list;

			} else {

				my $pointer_ref = shift(@{$pointer_array_ref});
				if (ref($pointer_ref) eq "HASH") {
					$self = $pointer_ref;
					return bless ($self, $class);
				}
				
			}

		} else {

			return;

		}

	} else {

		# just return an empty object
        return bless ($self, $class);
	}
}

sub pointer_id {

	my $self = shift;
	return $self->{pointer_id};

}

sub pointer_type {

	my ($self, $pointer_type_id) = @_;

	if ($pointer_type_id) { $self->{pointer_type_id} = $pointer_type_id }

	return $self->{pointer_type_id};

}

sub selection_id {

	my ($self, $selection_id) = @_;

	if ($selection_id) { $self->{selection_id} = $selection_id }

	return $self->{selection_id};

}

sub pointer {

	my ($self, $pointer) = @_;

	if ($pointer) { $self->{pointer} = $pointer }

	return $self->{pointer};

}


sub commit {

	my $self = shift;

	my $dbh = Lectio::DB->dbh();

	# see if the object has an id
	if ($self->pointer_id()) {
		
		# update the existing pointer
		my $return = $dbh->do('UPDATE pointer SET pointer_type_id = ?, selection_id = ?, pointer = ? WHERE pointer_id = ?', undef, $self->pointer_type(), $self->selection_id(), $self->pointer(), $self->pointer_id());

		if ($return > 1 || $return eq undef) { croak "Pointer update in commit() failed. $return records were updated." }

	} else {

		# get a new sequence
		my $id = Lectio::DB->nextID();

		# create a new record
		my $return = $dbh->do('INSERT INTO pointer (pointer_id, pointer_type_id, selection_id, pointer) VALUES (?, ?, ?, ?)', undef, $id, $self->pointer_type(), $self->selection_id(), $self->pointer());
		if ($return > 1 || $return eq undef) { croak 'Pointer commit() failed.'; }
		$self->{pointer_id} = $id;

	}

	return 1;

}

sub delete {

	my $self = shift;

	return 0 unless $self->{pointer_id};

	my $dbh = Lectio::DB->dbh();
	my $rv = $dbh->do('DELETE FROM pointer WHERE pointer_id = ?', undef, $self->{pointer_id});
	if ($rv != 1) { croak ("Delete failed. Deleted $rv records.") }

	return 1;

}

1;
