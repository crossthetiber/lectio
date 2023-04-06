package Lectio::Selection::Type;

use Lectio::DB;
use Carp;
use strict;

=head1 NAME

Lectio::Selection::Type

=head1 SYNOPSIS

	# use the module
	use Lectio::Selection::Type;

	# create a selection type object
	my $type = Lectio::Selection::Type->new();

	# fill in some attributes
	$type->type_name('Chapter');
	$type->type_description('This is a division of a book.');

	# discover this type id
	my $type_id = $type->type_id();

	# get a hash of all available types
	my %selection_types = Lectio::Selection::Type->get_types();

	# save the type to the database
	$type->commit();

	# delete the type
	$type->delete();

=head1 DESCRIPTION

This module, which is a child of the Selection.pm module, provides an interface for working with selection types in Lectio. A type is really a label along with a description, and assists with the cognitive organization of selections within a given collection. A type may be, for example, a chapter or page from a book. If the collection is a collection of audio format lectures given by a faculty member, then a type may be "Date" or "Syllabus Topic" such that the audio recordings could be organized logically or in sequence. The type names and descriptions can also be used to create directories of content. For example, a table of contents could be created, or a virtual map of PDF documents.

=head1 METHODS

This section outlines the various methods available in this module.

=head2 new()

Use this method to create a selection type object. Called with no options, this method creates an empty object. Called with a selection type id, this method will create a selection type object which had previously been committed to the database. Type names should be unique within the database. Only create a type if that type does not currently exist.

	# create a new type object
	my $type = Lectio::Selection::Type->new();

	# create a pre-existing type object
	my $type = Lectio::Selection::Type->new(id => 36);

	# create a stored type using the type name
	my $type = Lectio::Selection::Type->new(name => 'Chapter');

=head2 type_id()

This method simply returns the current selection type id number. The method cannot be used to assign an id, only retrieve the id.

	# discover the current selection type id
	my $type_id = $type->type_id();

=head2 type_name()

Use this method to set or get the selection type name. The name should represent a logical designation within the collection heirarchy.

	# set the type name
	$type->type_name('Chapter');

	# get the type name
	my $type_name = $type->type_name();

=head2 type_description()

Use this method to set or get the selection type description. The description exists merely for oraganizational purposes.

	# set the type description
	$type->type_description('This is a division of a book.');

	# get the type description
	my $type_description = $type->type_description();

=head2 get_types()

This method will return a hash of all available types in the Lectio database. This is a class method.

	# return list of selection types
	my %selection_types = Lectio::Selection::Type->get_types();

=head2 commit()

This method is used to save changes to a type description or create a new type description.

	# commit the type
	$type->commit()

=head2 delete()

Use this method to delete a selection type.

	# delete the type
	$type->delete()

=head1 AUTHOR

	Robert Fox <rfox2@nd.edu>

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

		my $dbh = Lectio::DB->dbh();

		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM selection_type WHERE type_id = ?', undef, $opts{id});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}
	} elsif ($opts{name}) {
		
		my $dbh = Lectio::DB->dbh();

		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM selection_type WHERE type_name = ?', undef, $opts{name});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}
	}

	# return the object
	return bless ($self, $class);

}

sub type_id {

	my $self = shift;
	return $self->{type_id};

}

sub type_name {

	my ($self, $type_name) = @_;

	if ($type_name) { $self->{type_name} = $type_name }

	return $self->{type_name};

}

sub type_description {

	my ($self, $type_description) = @_;

	if ($type_description) { $self->{type_description} = $type_description }

	return $self->{type_description};
}

sub get_types {

	my ($class, %opts) = @_;

	my $dbh = Lectio::DB->dbh();
	my $ary_ref = $dbh->selectall_arrayref('SELECT type_id, type_name FROM selection_type');

	if ($ary_ref) {

		my @return_rows = ();
		foreach my $row (@$ary_ref) {
			foreach my $row_data (@$row) {
				push(@return_rows, $row_data);
			}
		}

		return @return_rows;

	} else {

		return;

	}

}


sub commit {

	my $self = shift;
	my $dbh = Lectio::DB->dbh();

	# see if the object has an id
	if ($self->type_id()) {

		# update the existing selectio type
		my $return = $dbh->do('UPDATE selection_type SET type_name = ?, type_description = ? WHERE type_id = ?', undef, $self->type_name(), $self->type_description(), $self->type_id());

		if ($return > 1 || $return eq undef) { croak "Selection type update in commit() failed. $return records were updated." }

	} else {

		# get a new sequence
		my $id = Lectio::DB->nextID();

		# create a new record
		my $return = $dbh->do('INSERT INTO selection_type (type_id, type_name, type_description) VALUES (?, ?, ?)', undef, $id, $self->type_name(), $self->type_description());

		if ($return > 1 || $return eq undef) { croak 'Selection type commit() failed.'; }

		$self->{type_id} = $id;

	}

	return 1;

}

sub delete {

	my $self = shift;

	return 0 unless $self->{type_id};

	my $dbh = Lectio::DB->dbh();
	my $rv = $dbh->do('DELETE FROM selection_type WHERE type_id = ?', undef, $self->{type_id});

	if ($rv != 1) { croak ("Delete failed. Deleted $rv records.") }

	return 1;

}

1;
