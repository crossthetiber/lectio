package Lectio::Selection;

use Lectio::DB;
use Carp;
use strict;

=head1 NAME

Lectio::Selection

=head1 SYNOPSIS

	# use the module
	use Lectio::Selection;
	
	# create a selection object
	my $selection = Lectio::Selection->new();

	# fill in some attributes
	$selection->selection_name('Algebrae');
	$selection->id();
	$selection->parent_id('456');
	$selection->type_id('857');
	$selection->collection_id('9765');
	$selection->next_selection('890');
	$selection->previous_selection('123');
	$selection->selection_note('This selection corresponds to archive image 123.TIFF.');
	$selection->full_text('This is the full text of the selection.');
	$selection->ascension_number('123');
	$selection->context('right hand');

	# find the next or previous full path to the selection's digital object
	my $next_path = $selection->selection_path(pos => 'next', type_name => 'JPEG Large');
	my $prev_path = $selection->selection_path(pos => 'prev', type_name => 'JPEG Large');
	
	# find a set of selections with a certain kind of feature
	my @selection_group = Lectio::Selection->selection_find(selection_note => "large photographs");

	# assign or delete pointers from this selection
	my $return = $selection->pointer(action => 'add', pointer => '1_2_3_large.jpg', type_name => 'JPEG Large');

	# return all selections of a particular type
	my @selections = Lectio::Selection->get_selections(type => 'Volume');
	my @selections = Lectio::Selection->get_selections(type => 'Volume', sort => 'ascension');

	# return all immediate children of a given selection
	my @child_selections = $selection->children();

	# save the selection to the database
	$selection->commit();

	# delete this selection from the database
	$selection->delete();

=head1 DESCRIPTION

This module will allow the establishment and retrieval of selection obects within a Lectio database. The object contains certain properties of a selection such as the selection id, it's collection id, it's proper name, a parent id if applicable, and a selection type id. The object key, the selection id, will link this selection to possibly numerous pointers to external repository bitstreams (which may be text, compressed image data, audio recordings, etc). All of the attributes can be retrieved or set using the methods in this module.

=head1 METHODS

This section outlines the various methods available in this module.

=head2 new()

Use this method to create a selection object. Called with no options, this method creates an empty object. Called with a selection id, this method will create an object which relates to a specific selection with metadata from the underlying database.

	# create a new selection object
	my $selection = Lectio::Selection->new();

	# create a pre-exisiting selection object
	my $selection = Lectio::Selection->new(id => 15);

=head2 id()

This method returns an integer representing the database key of the currently created selection object.

	# get id of current selection object
	my $id = $selection->id();

The id attribute cannot be set.

=head2 selection_name()

This method either sets or retrieves the selection proper name.

	# set the selection name
	$selection->selection_name('Algebrae');

	# get the selection name
	my $selection_name = $selection->selection_name();

=head2 parent_id()

The parent id is another selection in a particular collection. A given selection can only have one parent, and the child selection is always somehow subsidiary to the parent selection. For example, a parent selection could be a volume or a book, and a child selection could be a chapter or a page. In an image collection, a parent could be a group photo and it's children could be photos of individual people. However, there is no reason why a selection could not be it's own parent. For example, the first page of a chapter could represent the chapter as a whole as well as page 356 of a book. In this case, the pointers for both selection objects would be identical. By default, this method will make sure that the selection indicated as the parent exists in the database. This funtionality can be shut off by using the parameter integrity with the value 'off'.

	# set the parent id
	$selection->parent_id(567);

	# get the parent id
	my $parent_id = $selection->parent_id();

	# set the parent id sans relational integrity
	$selection->parent_id('456', integrity => 'off');

=head2 type_id()

The type id points to a selection type which describes the type of selection at hand. For example, a collection may be divided up intovolumes, books, chapters and pages. The type simply allows us to label and describe the heirarchy for the collection. This method can be used to either get or set the selection type id.

	# set the type id
	$selection->type_id('857');

	# get the type id
	my $type_id = $selection->type_id();

=head2 collection_id()

The collection id is the parent of many selections. The selections can be subdivided in whatever way is necessary to organize the collection, but the collection groups them all together into an organic whole. This method allows either the setting or retrieving of the parent collection id.

	# set the collection id
	$selection->collection_id('9765');

	# get the collection id
	my $collection_id = $selection->collection_id(); 

=head2 next_selection()

This method provides access to the next selection id in the sequence of selections within a collection. This method can be used to assign or reassign the next selection id, as well as retrieve the appropriate selection id.

	# set the next selection id
	$selection->next_selection('15');

	# get the next selection id
	my $next_page = $selection->next_selection();

=head2 previous_selection()

This method provides the flip side to the next_selection method. The previous selection object id can either be set or retrieved using this method.

	# set the previous selection id
	$selection->previous_selection('23');

	# get the previous selection id
	my $previous_page = $selection->previous_selection();

=head2 selection_note()

Use this method to set or get the selection note. A selection note can contain special information about this selection such as image properties, the relation of the selection to it's corresponding digital objects, etc.

	# set the selection note
	$selection->selection_note('This selection corresponds to archive image 145.TIFF');

=head2 full_text()

The full text of a given selection may be store with the selection metadata in the database. Use this method to set this value or retrieve it.

	# set the full text
	$selection->full_text('This represents the full text of the selection.');

	# get the full text
	my $full_text_segment = $selection->full_text();

=head2 ascension_number()

This method should be used to manipulate the optional ascension number for a selection.

	# set the ascension number
	$selection->ascension_number('123');

	# get the ascension number
	my $number = $selection->ascension_number();

=head2 context()

Use this method to indicate a particular orientation, disposition or situation relevant to the current selection. For example, is this object odd or even? Is it right hand or left hand? This is especially useful if there are bipolar options or a descrete number of often repeated options.

	# set the context
	$selection->context('right hand');

	# get the context
	my $handedness = $selection->context();

=head2 selection_path()

This method will return the full path plus pointer for either the next or previous selection in the collection. Depending on the application and collection, the path may be a fully qualified URL or a local file system path that can be translated into a URL path. A relative path may also be suitable. This method currently takes only one argument which is the position direction, either next pre prev. Also, and importantly, this method will choose the next selection which is in the same pointer type category as this selection. In other words, if there are two pointer types, 'JPEG Large' and 'JPEG Small', and this selection is a member of the former pointer category, the next or previous pointer chosen will fall into the 'JPEG Large' category. The developer must indicate which pointer type for the current selection which they are interested in, so that the method can correctly determine which pointer is "next" or "previous". Examples follow:

	# get the next path plus pointer
	my $next_selection_path = selection_path(pos => 'next', type_name => 'JPEG Large');
	my $prev_selection_path = selection_path(pos => 'prev', type_name => 'JPEG Small');

=head2 selection_find()

This is a class method that can be used to locate a group of selection objects which share a certain feature. Currently, only one feature type is searchable: the selection note. However, other attribute types can be added as required. This method could be used as a searching mechanism, a feed for an indexer or possibly as a tool for syndicating content from a given collection. This method will always return selection objects. If no matching records are found, the method will return null. If the method is not called in a list context, only the last record of the group will be returned (if any at all).

	# find a group of selections with a certain sequence of text characters
	my @selection_group = Lectio::Selection->selection_find(selection_note => "large photographs");

=head2 pointer()

This method will either create or delete pointers for the current selection. The required parameters for adding a pointer are name of the action, the pointer string, and the name of the pointer type with which the pointer should be associated. If deleting a pointer, the action should be supplied along with the name of the pointer. Pointer names for a given selection should always be unique. Examples of usage follow. This method will return positive if the action was accomplished and will simply cause the calling application to croak if not.

	# create a new pointer for this selection
	$selection->pointer(action => 'add', pointer => '1_2_3_large.jpg', type_name => 'JPEG Large');

	# delete a pointer for this selection
	my $return = $selection->pointer(action => 'delete', pointer => '1_2_3_large.jpg');

=head2 get_selections()

Use this class method to retrieve a group of selection ids which are related in some way. Currently, the only available criteria is the name of the type to which a group of selections belong to. If no selections belong to a particular group, then a null result will be returned. Be warned that this method has the potential to return a set of thousands of members in a particular group since it does not discriminate according to context. The returned ids can also be sorted by the ascension numbers of the group if the sort parameter is supplied.

	# return all selection ids for selections which are 'Volume'(s)
	my @selections = Lectio::Selection->get_selections(type => 'Volume');

	# return results sorted by ascension number
	my @selections = Lectio::Selection->get_selections(type => 'Volume', sort => 'ascension');

=head2 children()

This method will return all immediate children (selection ids) of a given selection. The sort parameter can be included so that the results are returned in a specific order. Currently, only ascension number order is available.

	# return all immediate children of a given selection
	my @child_selections = $selection->children();

	# return results in ascension number order
	my @child_selections = $selection->children(sort => 'ascension');

=head2 commit()

This method simply commits the selection object to the database along with any attribute modifications using the attribute methods. If a new object is being created, this method will increment the sequence id and create a new record in the database.

This method will return true on success. Behavior which checks for database integrity can be turned off by using the strict => 'off' parameter.

	# commit the current selection object to the database
	$selection->commit();

	# turn off database integrity checks
	$selection->commit(strict => 'off');

=head2 delete()

This method will delete a selection object from the database along with all of it's associated relationships.

	# delete this selection from the database
	$selection->delete();

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
		my $rv = $dbh->selectrow_hashref('SELECT * FROM selection WHERE selection_id = ?', undef, $opts{id});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}

	} elsif ($opts{name}) {
	
		my $dbh = Lectio::DB->dbh();

		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM selection WHERE selection_name = ?', undef, $opts{name});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}
	}

	# return the object
	return bless ($self, $class);

}

sub id {

	my $self = shift;
	return $self->{selection_id};

}

sub selection_name {

	my ($self, $selection_name) = @_;

	if ($selection_name) { $self->{selection_name} = $selection_name }

	return $self->{selection_name};

}

sub selection_note {

	my ($self, $selection_note) = @_;

	if ($selection_note) { $self->{selection_note} = $selection_note }

	return $self->{selection_note};

}

sub full_text {

	my ($self, $full_text) = @_;

	if ($full_text) { $self->{full_text} = $full_text }

	return $self->{full_text};

}

sub ascension_number {

	my ($self, $ascension_number) = @_;

	if ($ascension_number) { $self->{ascension_number} = $ascension_number }

	return $self->{ascension_number};

}

sub context {

	my ($self, $context) = @_;

	if ($context) { $self->{context} = $context }

	return $self->{context};

}

sub collection_id {

	my ($self, $collection_id) = @_;

	if ($collection_id) { $self->{coll_id} = $collection_id }

	return $self->{coll_id};
}

sub parent_id {

	my ($self, $parent_id, %opts) = @_;

	if ($opts{integrity} eq 'off') {
		if ($parent_id) { $self->{parent_id} = $parent_id }
	} else {
		if ($parent_id) {
			my $selection = Lectio::Selection->new(id => $parent_id);
			if ($selection) { 
				$self->{parent_id} = $parent_id;
			} else {
				croak "Invalid parent id association attempted.";				
			}
		}
	}

	return $self->{parent_id};
}

sub type_id {

	my ($self, $type_id) = @_;

	if ($type_id) { $self->{type_id} = $type_id }

	return $self->{type_id};
}

sub next_selection {

	my ($self, $next_selection_id) = @_;

	if ($next_selection_id) { $self->{next_selection_id} = $next_selection_id }

	return $self->{next_selection_id};	
}

sub previous_selection {

	my ($self, $previous_selection_id) = @_;

	if ($previous_selection_id) { $self->{previous_selection_id} = $previous_selection_id }

	return $self->{previous_selection_id};
}

sub pointer {

	my ($self, %opts) = @_;

	# use the module
	use Lectio::Pointer;

	if ($opts{action} eq 'add') {
		
		my $pointer = Lectio::Pointer->new();
		my $pointer_type_id = Lectio::Pointer::Type->new(name => $opts{type_name})->pointer_type_id();
		$pointer->pointer_type($pointer_type_id);
		$pointer->selection_id($self->id());
		$pointer->pointer($opts{pointer});
		$pointer->commit();
		
	} elsif ($opts{action} eq 'delete') {

		my $pointer = Lectio::Pointer->new(name => $opts{pointer});
		$pointer->delete();

	} elsif ($opts{action} eq 'check') {

		my @pointers = Lectio::Pointer->new(name => $opts{pointer});

		if (scalar(@pointers)) {

			foreach my $pointer (@pointers) {
				# check type
				my $pointer_type_id = $pointer->pointer_type();
				if ((Lectio::Pointer::Type->new(id => $pointer_type_id))->pointer_type_name() eq $opts{type_name} && $pointer->selection_id() == $self->id()) {

					return 1;
					last;
				}

			}

			return 0;

		} else {

			return 0;

		}

	}

	return 1;	

}

sub get_selections {

	my ($class, %opts) = @_;

	my $dbh = Lectio::DB->dbh();

	if ($opts{'type'}) {

		use Lectio::Selection::Type;
		my $type_name = $opts{'type'};
		my $selection_type = Lectio::Selection::Type->new(name => $type_name);
		my $selection_type_id = $selection_type->type_id();		
		my $ary_ref;
		unless ($opts{'sort'}) {
			$ary_ref = $dbh->selectcol_arrayref('SELECT selection_id FROM selection WHERE type_id = ?', undef, $selection_type_id);
		} elsif ($opts{'sort'}) {

			if ($opts{'sort'} eq 'ascension') {
				$ary_ref = $dbh->selectcol_arrayref('SELECT selection_id FROM selection WHERE type_id = ? ORDER BY ascension_number', undef, $selection_type_id);
			} else {
				$ary_ref = $dbh->selectcol_arrayref('SELECT selection_id FROM selection WHERE type_id = ?', undef, $selection_type_id);
			}

		}

		if (scalar(@$ary_ref)) {
			return @$ary_ref;
		} else {
			return;
		}

	} else {

		return;

	}

}

sub children {

	my ($self, %opts) = @_;

	my $parent_id = $self->id();

	my $dbh = Lectio::DB->dbh();

	my $ary_ref;
	unless ($opts{'sort'}) {
		$ary_ref = $dbh->selectcol_arrayref('SELECT selection_id FROM selection WHERE parent_id = ?', undef, $parent_id);
	} elsif ($opts{'sort'} eq 'ascension') {
		$ary_ref = $dbh->selectcol_arrayref('SELECT selection_id FROM selection WHERE parent_id = ? ORDER BY ascension_number', undef, $parent_id);
	}

	if (scalar(@$ary_ref)) {
		return @$ary_ref;
	} else {
		return;
	}
	
}

sub commit {

	my ($self, %opts) = @_;

	unless ($self->type_id()) {
		croak "Missing selection type id in commit().";
	}

	unless ($self->selection_name()) {
		croak "Missing selection name in commit().";
	}

	unless ($self->collection_id()) {
		croak "Missing collection id in commit().";
	}

	my $dbh = Lectio::DB->dbh();

	# see if the object has an id
	if ($self->id()) {

		use Lectio::Collection;
		my $collection = Lectio::Collection->new(id => $self->collection_id());
		unless ($collection) {
			unless ($opts{strict} eq 'off') {
				croak "Submitted collection id not found in commit()";
			}
		}

		use Lectio::Selection::Type;
		my $type = Lectio::Selection::Type->new(id => $self->type_id());
		unless ($type) {
			unless ($opts{strict} eq 'off') {
				croak "Submitted type id not found in commit()";
			}
		}

		# update the existing selection
		my $return = $dbh->do('UPDATE selection SET coll_id = ?, selection_name = ?, parent_id = ?, type_id = ?, next_selection_id = ?, previous_selection_id = ?, selection_note = ?, full_text = ?, ascension_number = ?, context = ? WHERE selection_id = ?', undef, $self->collection_id(), $self->selection_name(), $self->parent_id(), $self->type_id(), $self->next_selection(), $self->previous_selection(), $self->selection_note(), $self->full_text(), $self->ascension_number(), $self->context(), $self->id());

		if ($return > 1 || $return eq undef) { croak "Selection update in commit() failed. $return records were updated." }

	} else {

		# get a new sequence
		my $id = Lectio::DB->nextID();

		use Lectio::Collection;
		my $collection = Lectio::Collection->new(id => $self->collection_id());
		unless ($collection) {
			unless ($opts{strict} eq 'off') {
				croak "Submitted collection id not found in commit()";
			}
		}

		use Lectio::Selection::Type;
		my $type = Lectio::Selection::Type->new(id => $self->type_id());
		unless ($type) {
			unless ($opts{strict} eq 'off') {
				croak "Submitted type id not found in commit()";
			}
		}

		# create a new record
		my $return = $dbh->do('INSERT INTO selection (selection_id, coll_id, selection_name, parent_id, type_id, next_selection_id, previous_selection_id, selection_note, full_text, ascension_number, context) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', undef, $id, $self->collection_id(), $self->selection_name(), $self->parent_id(), $self->type_id(), $self->next_selection(), $self->previous_selection(), $self->selection_note, $self->full_text(), $self->ascension_number(), $self->context());
		if ($return > 1 || $return eq undef) { croak 'Selection commit() failed.'; }
		$self->{selection_id} = $id;

	}

	return 1;

}

sub delete {

	my $self = shift;

	return 0 unless $self->{selection_id};

	my $dbh = Lectio::DB->dbh();
	my $rv = $dbh->do('DELETE FROM selection_authorship WHERE selection_id = ?', undef, $self->{selection_id});
	my $pointer_ids = $dbh->selectcol_arrayref('SELECT pointer_id FROM pointer WHERE selection_id = ?', undef, $self->{selection_id});
	foreach my $pointer_id (@{$pointer_ids}) {
		use Lectio::Pointer;
		my $pointer = Lectio::Pointer->new(id => $pointer_id);
		$pointer->delete();
	}
	my $rv = $dbh->do('DELETE FROM selection WHERE selection_id = ?', undef, $self->{selection_id});
	if ($rv != 1) { croak ("Delete failed. Deleted $rv records.") }

	return 1;

}


sub selection_path {

	my ($self, %opts) = @_;
	my $type_name = $opts{type_name};
	my $pointer_type = Lectio::Pointer::Type->new(name => $opts{type_name});
	my $pointer_type_path = $pointer_type->pointer_type_path();
	my $dbh = Lectio::DB->dbh();

	if ($opts{pos} eq 'prev') {
		my $previous_id = $self->previous_selection();
		my $rv = $dbh->selectcol_arrayref('SELECT p.pointer_id FROM pointer p, pointer_type pt WHERE pt.pointer_type_name = ? AND p.selection_id = ? AND p.pointer_type_id = pt.pointer_type_id', undef, $opts{type_name}, $previous_id);
		my $pointer_id = $rv->[0];
		my $pointer = Lectio::Pointer->new(id => $pointer_id);
		my $pointer_string = $pointer->pointer();
		my $path = "$pointer_type_path" . "$pointer_string";
		return $path;
	} elsif ($opts{pos} eq 'next') {
		my $next_id = $self->next_selection();
		my $rv = $dbh->selectcol_arrayref('SELECT p.pointer_id FROM pointer p, pointer_type pt WHERE pt.pointer_type_name = ? AND p.selection_id = ? AND p.pointer_type_id = pt.pointer_type_id', undef, $opts{type_name}, $next_id);
		my $pointer_id = $rv->[0];
		my $pointer = Lectio::Pointer->new(id => $pointer_id);
		my $pointer_string = $pointer->pointer();
		my $path = "$pointer_type_path" . "$pointer_string";
		return $path;
	} elsif ($opts{pos} eq 'current') {
		my $current_id = $self->id();
		my $rv = $dbh->selectcol_arrayref('SELECT p.pointer_id FROM pointer p, pointer_type pt WHERE pt.pointer_type_name = ? AND p.selection_id = ? AND p.pointer_type_id = pt.pointer_type_id', undef, $opts{type_name}, $current_id);
		my $pointer_id = $rv->[0];
		my $pointer = Lectio::Pointer->new(id => $pointer_id);
		my $pointer_string = $pointer->pointer();
		my $path = "$pointer_type_path" . "$pointer_string";
		return $path;
	}

	return 0;
}

sub selection_find {

	# this returns all objects matching input criteria

	my ($class, %opts) = @_;
	my $dbh = Lectio::DB->dbh();

	my @returned_selections = ();
	if ($opts{selection_note}) {
		my $rv = $dbh->selectcol_arrayref('SELECT selection_id FROM selection WHERE selection_note LIKE ?', undef, "\%$opts{selection_note}");
		my @selection_ids = @{$rv};
		foreach my $selection_id (@selection_ids) {
			my $selection = Lectio::Selection->new(id => $selection_id);
			push(@returned_selections, $selection);
		}
	}

	if (scalar(@returned_selections)) {
		return @returned_selections;
	} else {
		return;
	}

}

1;
