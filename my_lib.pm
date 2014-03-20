package my_lib;
use Config;
use File::Spec::Functions qw(catfile rel2abs);

sub import
{
  my $class = shift;
  my @libs = map rel2abs($_), @_;
  @libs || return;

  my @dirs = map {(catfile($_, 'share', 'perl5'), catfile($_, 'lib', 'perl5'))} @libs;

  my $s = $Config::Config{path_sep};
  my @perl5lib = !$ENV{PERL5LIB} ? () : split /$s/, $ENV{PERL5LIB};
  for my $dir (@dirs){
    ## add path to PERL5LIB ##
    grep($_ eq $dir, @perl5lib) || unshift @perl5lib, $dir;

    ## add path to @INC ##
    grep($_ eq $dir, @INC) || unshift @INC, $dir;
  }
  ## set PERL5LIB ##
  $ENV{PERL5LIB} = join $s, @perl5lib;
  ## set PATH ##
  $ENV{PATH} = join $s, map(catfile($_, 'bin'), @libs), $ENV{PATH};
}
1