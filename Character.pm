
package Character;

use strict;
use vars qw($AUTOLOAD %field);

# class def's
my $Start_Age = 5;

# class variables
my $SRAND_IS_SET = 0;

# object fields
my @attributes = qw (
                      name
                      sex
                      strength
                      constitution
                      charisma
                      age
                      father
                      mother
                      married
                      alive
                    );

# Authorize attribute fields
for my $attr ( @attributes ) { $field{$attr}++; }

sub AUTOLOAD {
  my $self = shift;
  my $attr = $AUTOLOAD;

  $attr =~ s/.*:://;

  #skip DESTROY and all-cap methods
  # (but we make an exception for ST/DX/IQ/HT methods)
  return unless ( $attr =~ m/[^A-Z]/); # || $attr =~ m/(IQ|DX|ST|HT)/);

  if (defined $field{$attr}) {
    $self->{uc $attr} = shift if @_;
    return $self->{uc $attr};
  } else {
    warn "invalid attribute method: ->$attr()";
  }

}

sub new {
  my $proto = shift;

  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto;
  my $self = {};

  bless($self, $class);
  # $self->parent($parent);

  # do this only once, during the creation of
  # the very first character 
  &_set_srand();

  $self->_init();

  return $self;

}

#
# Private Methods
#

# initalizes and resets the character object
# to base characteristics.
sub _init {
  my ($self) = @_;

  $self->name('');
  $self->alive(1);
  $self->age($Start_Age);
  $self->sex(&_calc_start_sex());
  $self->strength(&_calc_start_stat_value());
  $self->constitution(&_calc_start_stat_value());
  $self->charisma(&_calc_start_stat_value());

}

sub _calc_start_sex { 

   my $roll = int(rand(6)) + 1;
   my $sex = 'male';
   $sex = 'female' unless $roll < 4;

   return $sex;
}

sub _calc_start_stat_value { 

   # a number between 3 and 18 
   my $roll = int(rand(6)) + int(rand(6)) + int(rand(6)) + 3;

   my $value = 2;
   $value = 1 if ($roll < 16); 
   $value = 0 if ($roll < 13); 
   $value = -1 if ($roll < 9); 
   $value = -2 if ($roll < 6); 

   return $value;
}

# set the random seed when the first time
# a character is created.
sub _set_srand {

   unless ($SRAND_IS_SET) 
   {
     srand(time()^($$+($$ <<15)));
     $SRAND_IS_SET = 1;
   }

}

sub _get_attrib_hash {
   my (@attribs) = @_;
   my %attrib;
 
   while(@attribs) {
     my $key = shift @attribs;
     my $value = shift @attribs;
     $attrib{$key} = $value; 
   }
   return %attrib;
}

1;
