package OBO::Identified;
use Moose::Role;

has id => (is => 'rw', isa => 'Str');
has namespace => (is => 'rw', isa => 'Str');
has obsolete => (is => 'rw', isa=> 'Bool');
has deprecated => (is => 'rw', isa=> 'Bool');
has replaced_by => (is => 'rw', isa=>'ArrayRef[OBO::Node]');
has consider => (is => 'rw', isa=>'ArrayRef[OBO::Node]');

=head2 status

returns oneof: obsolete deprecated ok

=cut

sub status {
    my $self = shift;
    return 'obsolete' if $self->obsolete;
    return 'deprecated' if $self->deprecated;
    return 'ok';
}

sub is_identified {
    return defined shift->id;
}

sub id_db {
    (shift->get_db_local_id())[0];
}

sub local_id {
    (shift->get_db_local_id())[1];
}

sub get_db_local_id {
    my $id = shift->id;
    if ($id =~ /([\w\-]+):(.*)/) {
        return ($1,$2);
    }
    return ('_',$id);
}

1;

