package my_lib;
use Config;
use File::Spec::Functions qw(catfile rel2abs);

=head1 NAME

  my_lib - sets environment variables to use local library.

=head1 SYNOPSIS

  ## add /.../local/library/share/perl5,
  ##     /.../local/library/lib/perl5
  ## to PERL5LIB and @INC;
  ## add /.../local/library/bin to PATH
  use my_lib 'local/library';

=cut

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