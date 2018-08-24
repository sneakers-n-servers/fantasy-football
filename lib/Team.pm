package Team; 
use Mouse;

has 'number'    => (is => 'ro', isa => 'Num', required => 1);
has 'inventory' => (is => 'rw', isa => 'HashRef', required => 1);  

has 'team'      => (is => 'rw', isa => 'ArrayRef[Player]', default => sub {[]}); 
has 'total'     => (is => 'rw', isa => 'Num', default => 0); 
has 'variance'  => (is => 'rw', isa => 'Num', default => 0);

sub draft{
  my($self, $draft_ref, $remain_ref, $pick) = @_; 
  my %avail = %{$draft_ref};
  my %remain = %{$remain_ref};

  my $drafted = 0;
  foreach my $key (sort{$a <=> $b} keys %avail){
    my $cur_player = ${$avail{$key}};
    my $pos = lc($cur_player->position);

    if($self->inventory->{$pos} > 0 || ()){
      %avail = %{$self->select($cur_player, $pos, $pick, \%avail, $key)};
      $drafted = 1;
      last;  
    }
    elsif($self->inventory->{'flex'} > 0 && $pos ne 'qb'){
      %avail = %{$self->select($cur_player, 'flex', $pick, \%avail, $key)};
      $drafted = 1;
      last; 
    }
  }
  #If not drafted, go back to the larger list
  if(!$drafted){ 
     foreach my $key (sort{$a <=> $b} keys %remain){
       my $cur_player = ${$remain{$key}};
       my $pos = lc($cur_player->position);

       if($self->inventory->{$pos} > 0 || ()){
         %remain = %{$self->select($cur_player, $pos, $pick, \%remain, $key)};
         $drafted = 1;
         last;  
       }
       elsif($self->inventory->{'flex'} > 0){
         %remain = %{$self->select($cur_player, 'flex', $pick, \%remain, $key)};
         $drafted = 1;
         last; 
       }
     }
  }
  ($drafted == 1) || die("didnt draft!!\n");
  return(\%avail, \%remain); 
}

sub select{
  my($self, $player, $position, $pick, $hash_ref, $key) = @_; 
  my %avail = %{$hash_ref};
  
  #Address the flex, set the pick
  ($position eq 'flex') && $player->position('FLEX');
  $player->pick($pick); 
  push(@{$self->team}, $player);

  #Add to total, and readjust
  $self->total($self->total + $player->fpts->avg);
  $self->variance($self->variance + $player->variance);
  $self->inventory->{$position}--; 
  delete($avail{$key});
  return(\%avail);
}

sub to_str{ 
  my $self = shift;
  my $str1 = sprintf("Team %2d\n", $self->number);
  my $str2 = join('', map{$_->print_card} @{$self->team});
  my $str3 = sprintf("Total:  %.2f\n", $self->total);  
  my $str4 = sprintf("Variance:  %.2f\n", $self->variance);  
  join('', $str1, $str2, $str3, $str4); 
}

__PACKAGE__->meta->make_immutable();
1;
