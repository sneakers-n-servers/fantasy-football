#!/usr/bin/env perl
package Main;
use strict;
use warnings;
use LWP::UserAgent;
use JSON::Parse qw(parse_json);
use Text::Table;
use File::Basename; 

sub usage{ 
  my($exit_val, $mess) = @_;
  
  #Print error messages
  if($mess){ 
    my @lines = split("\n", $mess); 
    foreach(@lines){ print('ERROR: ', $_, "\n");};
    print("\n"); 
  }   
  my $script = basename($0);
  my $usage = <<"EOF";
Usage: $script [TEAMS]

EOF
  print($usage); 
  exit($exit_val);    
}

sub get_data{
  my $site = 'https://www.fantasypros.com/nfl/rankings/half-point-ppr-superflex.php';
  my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1});
  my $response = $ua -> get($site);
  ($response->is_success) ? return($response->decoded_content) : die $response->status_line; 
}

sub get_json{
  my @all_data = split("\n", get_data());
  my @player_lines = grep(/^\s*var\s+ecrData\s*=\s*\{.+$/, @all_data);
  (scalar(@player_lines) == 1) || die "ERROR: expecting 1 player line";
  my $player_line = $player_lines[0]; 
  $player_line =~ s/^\s*var\s+ecrData\s*=\s*(.+)$/$1/;
  $player_line =~ s/;$//;
  my $json = parse_json($player_line); 
  return($json);
}

sub output{
  my $team_filter = shift;
  my $json = get_json();
  my @players = @{$json ->{players}};
  my $count = 1;
  foreach(@players){
    $_->{rank} = $count; 
    $count++; 
  }
  if($team_filter ne ""){
    @players = grep($_->{player_team_id} =~ /^($team_filter)$/i, @players); 
  }
  my @deref = ();
  foreach(@players){
    push(@deref, [$_->{rank}, $_->{player_name}, $_->{player_team_id}, $_->{pos_rank}]);
  }
  my $table = Text::Table->new('Rank', 'Name', 'Team', 'Position Rank');
  $table->load(@deref);
  print($table); 
}

# Check for help
my %params = map{$_ => 1} @ARGV;
exists($params{'--help'}) && usage(0);

my $team_filter = join('|', @ARGV);
output($team_filter);
