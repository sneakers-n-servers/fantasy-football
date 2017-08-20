package Player;
use Mouse;

has 'name'     => (is => 'ro', isa => 'Str', required => 1);
has 'team'     => (is => 'ro', isa => 'Str', required => 1);
has 'position' => (is => 'rw', isa => 'Str', required => 1);
has 'uuid'     => (is => 'ro', isa => 'Str', required => 1);

has 'values'   => (is => 'ro', isa => 'ArrayRef[Stat]', default => sub {[]}); 
has 'fpts'     => (is => 'rw', isa => 'Stat', default => sub {Stat->new(avg => 0, high=> 0, low => 0)});
has 'variance' => (is => 'rw', isa => 'Num', default => 0);  
has 'value'    => (is => 'rw', isa => 'Num', default => 0); 
has 'pick'     => (is => 'rw', isa => 'Num', default => 0);   

sub push_stat{ 
  my($self, $val) = @_;
  push(@{$self->values}, $val);  
}

sub to_csv{ 
  my($self, $printv) = @_;
  my $string = ($printv) ? 
    join('|', $self->name, $self->position, $self->team, $self->fpts->to_csv, $self->value, $self->variance) :
    join('|', $self->name, $self->position, $self->team, $self->fpts->to_csv); 
  return($string);  
} 

sub print_card{ 
  my $self = shift;
  my $str = sprintf("%02d%-6s%-20s%.2f\n", $self->pick, $self->position . ':', $self->name, $self->fpts->avg);
  return($str);
}

sub to_str{
  my $self = shift; 
  my @stat = map{$_->to_str} @{$self->values};
  my $string = join('|', $self->name, $self->position, $self->team, $self->fpts->to_str, $self->variance);
  return($string); 
}

__PACKAGE__->meta->make_immutable();
1;
