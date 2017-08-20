package QB; 
use Mouse; 
use Stat;

extends 'Player';

has 'passing_yds' => (is => 'rw', isa => 'Stat');
has 'passing_tds' => (is => 'rw', isa => 'Stat');
has 'ints'        => (is => 'rw', isa => 'Stat');
has 'rushing_yds' => (is => 'rw', isa => 'Stat');
has 'rushing_tds'  => (is => 'rw', isa => 'Stat');
has 'fumbles'      => (is => 'rw', isa => 'Stat');

sub calculate{
  my ($self, $scoring_ref) = @_;
  my %scoring = %{$scoring_ref}; 
  my @vals = @{$self->values};
  (scalar(@vals) == 10) || die "Quarterback does not have enough values"; 

  $self->passing_yds($vals[2]);
  $self->passing_tds($vals[3]); 
  $self->ints($vals[4]); 
  $self->rushing_yds($vals[6]);
  $self->rushing_tds($vals[7]); 
  $self->fumbles($vals[8]);  

  my($high, $low); 
  foreach(Stat->meta->get_all_attributes){
    my $hi_lo = $_->name;
    my $calc = (
      ($self->passing_yds->$hi_lo / $scoring{'passing_yds'}) +
      ($self->passing_tds->$hi_lo * $scoring{'passing_tds'}) + 
      ($self->ints->$hi_lo *  $scoring{'ints'})              + 
      ($self->rushing_yds->$hi_lo / $scoring{'rushing_yds'}) + 
      ($self->rushing_tds->$hi_lo * $scoring{'rushing_tds'}) + 
      ($self->fumbles->$hi_lo * $scoring{'fumbles'})
    );
    $self->fpts->$hi_lo($calc); 
    ($high = $calc)if($hi_lo eq 'high');
    ($low = $calc)if($hi_lo eq 'low');
  }
  $self->variance(sprintf("%.2f", $high - $low));
}

__PACKAGE__->meta->make_immutable();
