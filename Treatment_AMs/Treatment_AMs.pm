##############################
#
# Bio::Genex::Treatment_AMs
#
# created on Mon Jan 15 11:06:36 2001 by /home/jasons/work/GeneX-WWW-Installer/Genex/scripts/create_genex_class.pl --dir=/home/jasons/work/GeneX-WWW-Installer/Genex --target=Treatment_AMs
#
# cvs id: $Id: Treatment_AMs.pm,v 1.9.2.1 2001/01/15 18:52:02 jes Exp $ 
#
##############################
package Bio::Genex::Treatment_AMs;

use strict;
use POSIX 'strftime';
use Carp;
use DBI;
use IO::File;
use Bio::Genex::DBUtils qw(:CREATE
		      :ASSERT
		      fetch_last_id
		     );
# import the fkey constants and undefined
use Bio::Genex qw(undefined);
use Bio::Genex::Fkey qw(:FKEY);

use ObjectTemplate 0.21;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $FKEYS $COLUMN2NAME $NAME2COLUMN $COLUMN_NAMES %_CACHE $USE_CACHE $LIMIT $FKEY_OBJ2RAW $TABLE2PKEY);

require Exporter;

@ISA = qw(ObjectTemplate Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw();

BEGIN {
  $USE_CACHE = 1;

  %_CACHE = ();

  $COLUMN_NAMES = [
          'am_fk',
          'tl_fk'
        ]
;
 $FKEYS = {
          'am_obj' => bless( {
                               'fkey_type' => 'LINKING_TABLE_OO',
                               'table_name' => 'ArrayMeasurement',
                               'fkey_name' => 'am_obj',
                               'pkey_name' => 'am_pk'
                             }, 'Bio::Genex::Fkey' ),
          'tl_obj' => bless( {
                               'fkey_type' => 'LINKING_TABLE_OO',
                               'table_name' => 'TreatmentLevel',
                               'fkey_name' => 'tl_obj',
                               'pkey_name' => 'tl_pk'
                             }, 'Bio::Genex::Fkey' )
        }
;
  $TABLE2PKEY = {
          'ArrayMeasurement' => 'tl_fk',
          'TreatmentLevel' => 'am_fk'
        }
;

  $COLUMN2NAME  = {
          'tl_fk' => 'Treatment Level',
          'am_fk' => 'Array Measurement'
        }
;
  $NAME2COLUMN  = {
          'Treatment Level' => 'tl_fk',
          'Array Measurement' => 'am_fk'
        }
;
  $FKEY_OBJ2RAW = {
          'am_obj' => 'am_fk',
          'tl_obj' => 'tl_fk'
        }
;
}


attributes (no_lookup=>['fetched', 'fetch_all', 'fetched_attr', 'id', 'pkey_link'], lookup=>['am_fk', 'tl_fk', 'am_obj', 'tl_obj']);

sub table_name {return 'Treatment_AMs';} # probably unnecessary

sub fkeys {return $FKEYS;}

sub column2name {return $COLUMN2NAME;}

sub name2column {return $NAME2COLUMN;}

sub fkey_obj2raw {return $FKEY_OBJ2RAW;}

sub column_names {return $COLUMN_NAMES;}

sub table2pkey { return $TABLE2PKEY; }

sub linking_table { return 1; }

sub pkey_name {
  my $self = shift;
  my $name;
  
  # have we been called as a class method, or an instance method
  if (not ref($self)) {
    # class method invocation requires table name
    my $ref_table = shift;
    die "Bio::Genex::Treatment_AMs::pkey_name: Must specify a table argument" 
      unless defined $ref_table;
    # just in case we're given a class name
    $ref_table =~ s/Bio::Genex:://;
    $name = $TABLE2PKEY->{$ref_table};
    die "Bio::Genex::Treatment_AMs::pkey_name: table $ref_table not in TABLE2PKEY" 
      unless defined $name;
  } else {
    # instance method requires pkey_link
    $name = $self->get_attribute('pkey_link');
    die "Bio::Genex::Treatment_AMs::pkey_name: must set the 'pkey_link' attribute for linking tables classes" unless defined $name;
  }
  return $name;
}
#
# a workhorse function for retrieving multiple objects of a class
#
sub get_objects {
  my ($class) = shift;
  my @objects;
  my $COLUMN2FETCH;
  my $VALUE2FETCH;
  my $pkey_name;
  my $has_args = 0;
  if (ref($_[0]) eq 'HASH') {
    $has_args = 1;
    # we were called with an anonymous hash as the first parameter
    # grab it and parse the parameter => value pairs
    my $hashref = shift;
    $COLUMN2FETCH =  $hashref->{column} if exists $hashref->{column};
    $VALUE2FETCH =  $hashref->{value} if exists $hashref->{value};
    die "Bio::Genex::Treatment_AMs::get_objects: Must define both 'column' and 'value'" 
      if ((defined $VALUE2FETCH) && not (defined $COLUMN2FETCH)) || 
          ((defined $COLUMN2FETCH) && not (defined $VALUE2FETCH));

    # we are a linking table so the pkey_link must be set
    # that means the first element of @ids must be the string
    # 'pkey_link' and the second must be the value
    die "Bio::Genex::Treatment_AMs::get_objects: must set 'pkey_link' for linking class" 
      unless exists $hashref->{pkey_link};
    $pkey_name = $hashref->{pkey_link};
  }
  my @ids = @_;
  if (scalar @ids == 0 && ! $has_args) {
    croak("Bio::Genex::Treatment_AMs::get_objects called with no ID's
");
  } elsif (scalar @ids == 0 ||
           (scalar @ids == 1 && $ids[0] eq 'ALL')) {
    # the user is requesting all objects of type $class from the DB

    # empty the id list
    @ids = ();


    # using class methods seems indirect, but it deals
    # properly with inheritance
    my $FROM = [$class->table_name()];

    # we fetch *all* columns, so that we can populate the new objects
    my $COLUMNS = ['*'];
  
    my $dbh = Bio::Genex::current_connection();
    my @args = (COLUMNS=>$COLUMNS, FROM=>$FROM);
    if (defined $COLUMN2FETCH) {
      my $where =  "$COLUMN2FETCH = ". $dbh->quote($VALUE2FETCH);
      push(@args,WHERE=>$where);
    }
    push(@args,LIMIT=>$LIMIT) if defined $LIMIT;
    my $sql = create_select_sql($dbh,@args);
    my $sth = $dbh->prepare($sql) 
      or die "Bio::Genex::Treatment_AMs::get_objects:\nSQL=<$sql>,\nDBI=<$DBI::errstr>";
    $sth->execute() 
      or die "Bio::Genex::Treatment_AMs::get_objects:\nSQL=<$sql>,\nDBI=<$DBI::errstr>";

    # if there were no objects, return. decide whether to return an 
    # empty list or an empty arrayref using wantarray
    unless ($sth->rows()) {
      return () if wantarray;
      return []; # if not wantarray
    }

    # we use the 'NAME' attribute of the statement handle to get the
    # list of columns that were fetched.
    my @column_names = @{$sth->{NAME}};
    my $rows = $sth->fetchall_arrayref();
    die "Bio::Genex::Treatment_AMs::get_objects:\nSQL=<$sql>,\nDBI=<$DBI::errstr>" 
      if $sth->err;
    foreach my $col_ref (@{$rows}) {
      # we create a blank object, and populate it with data ourselves
      my $obj = $class->new();

      # %fetched_attrs is used to track which attributes have
      # already been retrieved from the DB, so that Bio::Genex::undefined
      # doesn't try to fetch them a second time if their value is undef
      my %fetched_attrs;
      for (my $i=0;$i < scalar @column_names; $i++) {
	no strict 'refs';
	my $col = $column_names[$i];
	$obj->$col($col_ref->[$i]);

	# record the column as fetched
	$fetched_attrs{$col}++;
      }
      # store the record of the fetched columns
      $obj->fetched_attr(\%fetched_attrs);

      # we are a linking table so the pkey_link attr must be set
      $obj->set_attribute('pkey_link',$pkey_name);

      # now we set the id so that delayed-fetching will work for
      # the OO attributes
      $obj->id($obj->get_attribute("$pkey_name"));
      push(@objects,$obj);
    }
    $sth->finish();
  } else {
    # we have been called with an @id_list
    die "Can't use 'column' and 'value' specifiers with an \@id_list"
      if defined $COLUMN2FETCH || defined $VALUE2FETCH;

    my $obj;
    foreach (@ids) {
      if ($USE_CACHE && exists $_CACHE{$_}) {
  	$obj = $_CACHE{$_};	# use it if it's in the cache
      } else {
  	my @args = (id=>$_);
  	push(@args,'pkey_link'=>$pkey_name);
  	$obj = $class->new(@args);
  
  	# if the id was bad, $obj will be undefined
  	next unless defined $obj;
  	$_CACHE{$_} = $obj if $USE_CACHE; # stick it in the cache for later
      }
      push(@objects, $obj);
    }
  }
  # decide whether to return a list or an arrayref using wantarray
  return @objects if wantarray;
  return \@objects; # if not wantarray
}


# ObjectTemplate automagically creates a new() method for us 
# that method invokes $self->initialize() after first setting all 
# parameters specified in invocation
sub initialize {
  my $self = shift;

  # we only need to be concerned with caching and id verification
  # if the user has specified and 'id'.
  my $id = $self->get_attribute('id');
  if (defined $id) {
    # 
    # executive decision: if it's in the cache, use it without
    # checking that the parameters are the same
    return $_CACHE{$id} if $USE_CACHE && 
      defined $id &&
      exists $_CACHE{$id};
  
    # 
    # The object is not in the cache, so now we check whether we've
    # been given a valid id
    #
    die "Bio::Genex::Treatment_AMs::initialize: Must set 'pkey_link' when calling new() with an id" 
      unless defined $self->get_attribute('pkey_link');
    my $pkey_name = $self->pkey_name();
    my $dbh = Bio::Genex::current_connection();
    my $FROM = [$self->table_name()];
    my $COLUMNS = [$pkey_name];
    my @args = (COLUMNS=>$COLUMNS, FROM=>$FROM, 
  		WHERE=> $pkey_name . " = '$id'");
    my $sql = create_select_sql($dbh,@args);
    my $count = scalar @{$dbh->selectall_arrayref($sql)};
    die "Bio::Genex::Treatment_AMs::initialize: $DBI::errstr" if $dbh->err;
  
    # if there was a problem, return an error to new(), so that 
    # new will return undef to the calling function
    if ($count < 1) {
      warn("Bio::Genex::Treatment_AMs::initialize: no DB entries for id: $id");
      return -1 unless $count > 0;
    }
  }

  #
  # now that we know we have a valid id, we can resume initialization
  #

  # we need to initialize these for Bio::Genex::undefined() to work
  $self->fetched(0);		# we have not retrieved data via fetch
  $self->fetched_attr({});	# no attr's have been delayed_fetched

  # actually get the object's data if we've been told to
  if (defined $self->get_attribute('fetch_all')) {
    die "Can't use 'fetch_all' without setting 'id'" unless defined $id;
    $self->fetch();
  }
}

sub fetch {
  my ($self) = @_;

  # recursion in this is bad
  return if $self->fetched();

  # can't fetch without a primary key to lookup the data
  my $pkey = $self->get_attribute('id');
  die "Must define an id for fetch"  unless defined $pkey;

  # we don't want to get into loops in Bio::Genex::undefined()
  $self->fetched(1);

  my $dbh = Bio::Genex::current_connection();

  # we make these method calls instead of hardcoding the values
  # for the purpose of inheritance
  assert_table_defined($dbh,$self->table_name());
  my $sql = create_select_sql($dbh,
                    COLUMNS=>['am_fk', 'tl_fk'],
                    FROM=>[$self->table_name()],
                    WHERE=>$self->pkey_name() . " = '$pkey'",
                              );
  my $sth = $dbh->prepare($sql) || die "Bio::Genex::Treatment_AMs::initialize: $DBI::errstr";
  $sth->execute() || die "Bio::Genex::Treatment_AMs::initialize: $DBI::errstr";

  # sanity check to see if bogus id
  my $ref = $sth->fetchrow_hashref();
  die "Treatment_AMs: ", $self->pkey_name(), " $pkey, not in DB"
    unless defined $ref;

  while (my ($key,$val) = each %{$ref}) {
    # no use for storing undef, since all attributes 
    # start as undef
    next unless defined $val;

    # we only want to set attributes that do not already exist
    # for example, we are called by update_db(), we don't want to force
    # users to call fetch() before modifying the object's attributes
    next if defined $self->get_attribute($key);

    { # we use this to temporarily relax the strict pragma
      # to use symbolic references
      no strict 'refs';
      $self->$key($val);
    } # back to our regularily scheduled strictness
  }
  $sth->finish();
}


=head1 NAME

Bio::Genex::Treatment_AMs - Methods for processing data from the GeneX DB
linking table: Treatment_AMs

=head1 SYNOPSIS

  use Bio::Genex::Treatment_AMs;

  # instantiating a linking table instance
  my $Treatment_AMs = Bio::Genex::Treatment_AMs->new(id=>47,pkey_link=>'am_fk');
  # or 
  my $Treatment_AMs = Bio::Genex::Treatment_AMs->new(id=>47,pkey_link=>'tl_fk');

  # retrieve data from the DB for all columns
  $Treatment_AMs->fetch();

  # creating an instance, without pre-fetching all columns
  my $Treatment_AMs = new Bio::Genex::Treatment_AMs(id=>47,
                                              'pkey_link'=>'am_fk');

  # creating an instance with pre-fetched data
  my $Treatment_AMs = new Bio::Genex::Treatment_AMs(id=>47, 
                                            'fetch_all'=>1,
                                            'pkey_link'=>'am_fk');

  # retrieving multiple instances via primary keys
  my @objects = Bio::Genex::Treatment_AMs->get_objects('pkey_link'=>'am_fk',
                                                  23,57,98);


  # retrieving all instances from a table
  my @objects = Bio::Genex::Treatment_AMs->get_objects('ALL');

  # retrieving the primary key for an object, generically
  my $primary_key = $Treatment_AMs->id();

  # retrieving other DB column attributes
  my $am_fk_val = $Treatment_AMs->am_fk();
  $Treatment_AMs->am_fk($value);

  my $tl_fk_val = $Treatment_AMs->tl_fk();
  $Treatment_AMs->tl_fk($value);


=head1 DESCRIPTION

Each Genex class has a one to one correspondence with a GeneX DB table
of the same name (I<i.e.> the corresponding table for Bio::Genex::Treatment_AMs is
Treatment_AMs).


B<NOTE>: Class Bio::Genex::Treatment_AMs is linking table class. This means
that it represents a table in the Genex DB which has no primary
key. Instead, there are two foreign keys that can be used to lookup a
value from the database. In Bio::Genex::Treatment_AMs, those two columns are
'am_fk' and 'am_fk'. When an instance of
Bio::Genex::Treatment_AMs is instantiated, either via C<new()> or
C<get_objects(@id_list)>, the 'C<pkey_link>' parameter must be
specified as one of these two values, otherwise, an error will result.


Most applications will first create an instance of Bio::Genex::Treatment_AMs
and then fetch the data for the object from the DB by invoking
C<fetch()>. However, in cases where you may only be accessing a single
value from an object the built-in L<delayed fetch|/DELAYED_FETCH>
mechanism can be used. All objects are created without pre-fetching
any data from the DB. Whenever an attribute of the object is accessed
via a getter method, the data for that attribute will be fetched from
the DB if it has not already been. Delayed fetching happens
transparently without the user needing to enable or disable any
features. 

Since data is not be fetched from the DB I<until> it is accessed by
the calling application, it could presumably save a lot of access time
for large complicated objects when only a few attribute values are
needed.

=head1 ATTRIBUTES

There are three different types of attributes which instances of
Bio::Genex::Treatment_AMs can access: I<raw> foreign key attributes,
Obect-Oriented foreign key attributes, and simple column attributes.

=over 4 

=item Raw Foreign Keys Attributes

=item Object Oriented Foreign Key Attributes

This mode presents foreign key attributes in a special way, with all
non-foreign key attributes presented normally. Foreign keys are first
retrieved from the DB, and then objects of the appropriate classes are
created and stored in slots. This mode is useful for applications that
want to process information from the DB because it automates looking
up information.

Specifying the 'C<recursive_fetch>' parameter when calling C<new()>,
modifies the behavior of this mode. The value given specifies the
number of levels deep that fetch will be invoked on sub-objects
created.

=item Simple Column Attributes

=back



=head1 CLASS VARIABLES

Class Bio::Genex::Treatment_AMs defines the following utility variables for assisting
programmers to access the Treatment_AMs table.

=over 4

=item $Bio::Genex::Treatment_AMs::LIMIT

If defined, $LIMIT will set a limit on any select statements that can
return multiple instances of this class (for example C<get_objects()>
or any call to a C<ONE_TO_MANY> or C<LOOKUP_TABLE> foreign key
accessor method).


=item $Bio::Genex::Treatment_AMs::USE_CACHE

This variable controls whether the class will cache any objects
created in calls to C<new()>. Objects are cached by primary key. The
caching is very simple, and no effort is made to track whether
different invocations of C<new()> are being made for an object with
the same primary key value, but with different options set. If you
desire to reinstantiate an object with a different set of parameters,
you would need to undefine C<$USE_CACHE> first.


=back


B<WARNING>: variables other than those listed here are for internal use
only and are subject to change without notice. Use them at your own
risk.

=head1 DELAYED FETCH

It is possible to retrieve only the subset of attributes one chooses
by simply creating an object instance and then calling the appropriate
getter function. The object will automatically fetch the value from
the DB when requested. This can potentially save time for large
complicated objects. This triggers a separate DB query for each
attribute that is accessed, whereas calling C<fetch()> will retrieve
all fields of the object with a single query.

For example:

  my $Treatment_AMs = Bio::Genex::Treatment_AMs->new(id=>47);
  my $val = $Treatment_AMs->am_fk();

The attribute's value is then cached in the object so any further calls
to that attribute's getter method do not trigger a DB query.

B<NOTE>: Methods may still return C<undef> if their value in
the DB is C<NULL>.


=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::Genex::Treatment_AMs->methodname() syntax.

=over 4

=item new(%args)

new() accepts the following arguments:

=over 4

=item id 

Numeric or string value. The value of the primary key for looking up
the object in the DB.


=item pkey_link

For linking tables this specifies which of the two possible values
should be used as the primary key to fetch an instance from the
DB. For class Bio::Genex::Treatment_AMs, 'C<pkey_link>' can be either 'C<am_fk>' or 'C<tl_fk>'.

=back


=item table2pkey()

For linking table classes, this method returns a hash table (not a
hashref) that defines the fkey access map. Linking tables have no
class-wide primary key, instead the column which is used to fetch rows
from the DB is determined on a per-instance basis depending on which
of the two linked-to tables is accessing the data. For example, in
Bio::Genex::Treatment_AMs if a method in class C<ArrayMeasurement> invokes its
foreign key accessor function, the column 'tl_fk' will be
used to fetch values from the DB.

=item linking_table()

Used by generic functions to determine if a specified class is a
linking table class. For Bio::Genex::Treatment_AMs it returns 1, since it I<is>
a linking table class.


=item table_name()

Returns the name of the DB table represented by this class. For
Bio::Genex::Treatment_AMs it returns 'Treatment_AMs';

=item column2name()

This method returns a hashref that translates DB column names into
human readable format.

=item name2column()

This method returns a hashref that is a reverse lookup table to
translate the human readable version of a DB column name back into the
column_name. This is useful for preparing table output in CGI scripts:


    %column2name = %{$class->column2name()};
    if (exists $column2name{$_}) {
      push(@column_copy,$column2name{$_});
    }
    
    # now that we've translated the names, we sort them
    @column_copy = sort @column_copy;
    
    # make a header element. 
    push(@rows,th(\@column_copy));


=item fkeys()

This method returns a hashref that holds all the foreign key entries
for the Treatment_AMs table.

=item column_names()

This method returns an array ref which holds the names of all the
columns in table Treatment_AMs.


    # first retrieve the data from the DB
    $object = $full_module_name->new(id=>$id);
    $object->fetch();

    # now extract the data from the object
    foreach (@{$class->column_names}) {
    # we use this to temporarily relax the strict pragma
    # to use symbolic references
      no strict 'refs';
      $tmp_values{$_} = $object->$_;

    # back to our regularily scheduled strictness
    }


=item get_objects({pkey_link=>'am_fk'}, @id_list)

=item get_objects('ALL')

=item get_objects({column=>'col_name',value=>'val'})

This method is used to retrieve multiple instances of class
Bio::Genex::Treatment_AMs simultaneously. For linking tables, there are three
different ways to invoke this method.

By passing in an C<@id_list>, get_objects() uses each element of the
list as a primary key for the Treatment_AMs table and returns a single
instance for each entry. This form of the method requires a hash
reference as the first argument. The hash must have the 'C<pkey_link>'
key defined.

B<WARNING>: Passing incorrect id values to C<get_objects()> will cause
a warning from C<Bio::Genex::Treatment_AMs::initialize()>. Objects will be
created for other correct id values in the list.

B<ERROR>: When using the @id_list form of this method with a linking
table, the 'C<pkey_list>' attribute B<must> be specified, otherwise an
error will result. This is because linking tables have two possible
columns to lookup from.

By passing the 'ALL' parameter, get_objects() returns an instance for
every entry in the table, and therefore, 'C<pkey_list>' doesn't need
to be specified.

By passing a hash reference that contains the 'column' and 'name'
keys, the method will return all objects from the DB whose that have
the specified value in the specified column.

B<NOTE>: When passing a hash reference with the 'column' and 'value'
keys specified, it is not necessary to specify the 'C<pkey_link>'
attribute.


=back



B<NOTE>: All objects must have the 'id' parameter set before attempting
to use C<fetch()> or any of the objects getter functions.

=head1 INSTANCE METHODS

The following methods can only be called by first having valid
instance of class Bio::Genex::Treatment_AMs.

=over 4


=item fetch()

This method triggers a DB query to retrieve B<ALL> columns from the DB
associated with this object.


=back



B<WARNING>: methods other than those listed here are for internal use
only and are subject to change without notice. Use them at your own
risk.


=head1 FOREIGN KEY ACCESSOR METHODS

There are two major categories of foreign key accessor methods:
I<Object Oriented> foreign key methods, and I<raw> foreign key
methods. 

Each foreign key column in the table is represented by B<two> methods,
one OO method and one raw method. The raw method enables fethcing the
exact numeric or string values stored in the DB. The OO method creates
objects of the class the fkey column refers to. The idea is that if
only the numeric fkey value is desired, the raw fkey method can be
used. If it is necessary to get attributes from the table referred to
by the fkey column, then the OO method should be invoked, and the
necessary methods on that object can be queried.

The names of the raw fkey methods is the same as the fkey columns in
the DB table they represent (all fkey columns end in the suffix
'_fk'). The OO methods have the same names as the column they
represent, with the difference that they have the suffix '_obj'
instead of '_fk'.

So for example, in class Bio::Genex::ArrayMeasurement the
'C<primary_es_fk>' column is represented by two methods, the raw
method C<primary_es_fk()>, and the OO method C<primary_es_obj>.

The following foreign key accessors are defined for class
Bio::Genex::Treatment_AMs:

=over 4


=back



Every foreign key in a DB table belongs to a certain class of foreign
keys. Each type of foreign key confers a different behavior on the
class that contains it. The classifications used in Genex.pm are:

=over 4

=item *

MANY_TO_ONE

If a class contains a foreign key of this type it will not be visible
to the API of that class, but instead it confers a special method to
the class that it references. 

For example, the Chromosome table has a MANY_TO_ONE foreign key,
spc_fk, that refers to the species table. Class L<Bio::Genex::Chromosome>, has
it\'s normal C<spc_fk()> attribute method, but no special foreign key
accessor method. However, class L<Bio::Genex::Species> is given a special
foreign key accessor method, C<chromosome_fk()> of type
ONE_TO_MANY. When invoked, this method returns a list of objects of
class L<Bio::Genex::Species>.

=item *

ONE_TO_MANY

The inverse of type MANY_TO_ONE. It is not an attribute inherent to a
given foreign key in any DB table, but instead is created by the
existence of a MANY_TO_ONE foreign key in another table. See the above
discussion about MANY_TO_ONE foreign keys.

=item *

LOOKUP_TABLE

This type of key is similar to type ONE_TO_MANY. However, However the
API will I<never> retrieve an object of this type. Instead it
retrieves a matrix of values, that represent the list of objects. It
is used in only two places in the API: L<Bio::Genex::ArrayMeasurement> and
L<Bio::Genex::ArrayLayout> classes with the C<am_spots()> and C<al_spots()>
accessor functions.

=item *

LINKING_TABLE

Foreign keys of this type appear in tables without primary keys. The
foreign keys are each of type LINKING_TABLE, and when invoked return
an object of the class referred to by the foreign key.

=item *

FKEY

A generic foreign key with no special properties. When invoked it returns
an object of the class referred to by the foreign key.

=back




=head1 ATTRIBUTE METHODS

These are the setter and getter methods for attributes in class
Bio::Genex::Treatment_AMs.

B<NOTE>: To use the getter methods, you may either invoke the
C<fetch()> method to retrieve all the values for an object, or else
rely on L<delayed fetching|/DELAYED_FETCH> to retrieve the attributes
as needed.

=over 4


=item id()

C<id()> is a special attribute method that is common to all the Genex
classes. This method returns the primary key of the given
instance. Class Bio::Genex::Treatment_AMs is a linking table and therefore it
can I<two> possible columns that represent the 'id'
('C<am_fk>' and 'C<tl_fk>'). When an instance of
class Bio::Genex::Treatment_AMs is created using either C<new()> or
C<get_objects(@id_list)> the 'C<pkey_link>' attribute must specified
as one of the two possible values.

The C<id()> method can be useful in writing generic methods because it
avoids having to know the name of the primary key column.

=item am_fk()

=item am_fk($value)

Methods for the am_fk attribute. This attribute is the first
possible value for the 'C<pkey_link>' attribute at object creation
time.

=item tl_fk()

=item tl_fk($value)

Methods for the tl_fk attribute. This attribute is the second
possible value for the 'C<pkey_link>' attribute at object creation
time.


=back



B<WARNING>: methods other than those listed here are for internal use
only and are subject to change without notice. Use them at your own
risk.

=head1 IMPLEMENTATION DETAILS

These classes are automatically generated by the
create_genex_classes.pl script.  Each class is a subclass of the
ObjectTemplate class (written by Sriram Srinivasan, described in
I<Advanced Perl Programming>, and heavily modified by Jason
Stewart). ObjectTemplate implements automatic class creation in perl
(there exist other options such as C<Class::Struct> and
C<Class::MethodMaker> by Damian Conway) via an C<attributes()> method
call at class creation time.

=head1 BUGS

Please send bug reports to genex@ncgr.org

=head1 LAST UPDATED

on Mon Jan 15 11:06:36 2001 by /home/jasons/work/GeneX-WWW-Installer/Genex/scripts/create_genex_class.pl --dir=/home/jasons/work/GeneX-WWW-Installer/Genex --target=Treatment_AMs

=head1 AUTHOR

Jason E. Stewart (jes@ncgr.org)

=head1 SEE ALSO

perl(1).

=cut

1;
