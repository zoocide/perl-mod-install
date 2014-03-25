#!/usr/bin/perl -w
use strict;
use Cwd;
use Config;
use File::Spec::Functions qw(rel2abs catfile);
use BasicTools;
use constant windoze => $^O eq 'MSWin32';

=head1 SYNOPSIS

  # install all required modules to directory install_dir
  bootstrap.pl install_dir

  # in your script 'use my_lib 'install_dir';' to access installed modules.

=cut

my $perl = $^X;

my $install_dir = $ARGV[0] ? rel2abs($ARGV[0]) : '';
my $prefix      = $install_dir ? 'PREFIX='.$install_dir : '';
my $temp_dir    = 'bootstrap_temp';

## set environment variables ##
require my_lib;
my_lib->import($install_dir);

## initialize BasicTools ##
my $bt = BasicTools->new;
$bt->init_tools;
$bt->has_make || !windoze || $bt->get_dmake($install_dir);

#sub my_system{ print join( ' ', @_, "\n"); 0 }
sub my_system{ system @_ }

## create $temp_dir ##
mkdir $temp_dir;

## install ExtUtils::MakeMaker ##
eval{ require ExtUtils::MakeMaker };
$@ && get_and_install_dist('http://search.cpan.org/CPAN/authors/id/B/BI/BINGOS/ExtUtils-MakeMaker-6.92.tar.gz');

## install ExtUtils::Manifest ##
eval{ require ExtUtils::Manifest };
$@ && get_and_install_dist('http://search.cpan.org/CPAN/authors/id/F/FL/FLORA/ExtUtils-Manifest-1.63.tar.gz');

## install Module::CoreList ##
eval{ require Module::CoreList };
$@ && get_and_install_dist('http://search.cpan.org/CPAN/authors/id/B/BI/BINGOS/Module-CoreList-3.07.tar.gz');

## install cpanminus ##
eval{ require App::cpanminus };
$@ && install_online_cpanm();

## install lib::xi ##
eval{ require lib::xi };
$@ && install_with_cpanm('lib::xi');

## install specified modules ##
require lib::xi;
lib::xi->import($install_dir);
require modules_to_install;


sub get_and_install_dist
{
  my $url = shift;
  $url =~ m#.*/((.*)\.tar\.gz)$# or die "can`t parse url '$url'\n";
  my ($fname, $dir) = map catfile($temp_dir, $_), ($1, $2);

  ## download package ##
  !-f $fname && $bt->download($url, $temp_dir);

  ## extract package ##
  !-d $dir   && $bt->extract($fname);

  ## install package ##
  my $cd = cwd();
  chdir($dir)                              || die "can`t change directory '$dir'\n";
  my_system($perl, 'Makefile.PL', $prefix) && die "can`t create makefile\n";
  $bt->make;
  $bt->make('install');
  chdir($cd);
  print "## $dir successfully installed ##\n";
}

sub install_online_cpanm
{
  my $url = 'http://cpanmin.us';
  my @opts = qw(App::cpanminus);
  my $cpanm = catfile($temp_dir, 'cpanm');
  $install_dir && unshift @opts, '-l', $install_dir;
  $bt->download($url, $cpanm);
  my_system($perl, $cpanm, @opts) && die "can`t install cpanminus\n";
  print "## cpanminus successfully installed ##\n";
}

sub install_with_cpanm
{
  my $module = shift;
  system('cpanm', '-l', $install_dir, $module) && die "## installation $module failed ##\n";
  print "## $module successfully installed ## \n";
}
