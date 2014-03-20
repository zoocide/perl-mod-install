#!/usr/bin/perl -w
use strict;
use Config;
use File::Spec::Functions qw(rel2abs catfile);

my $wget = 'wget';
my $wget_pipe = "wget -O -";
my @tar = qw(tar -xf);
my $make = 'make';
my $perl = $^X;

my $install_dir = $ARGV[0] ? rel2abs($ARGV[0]) : '';
my $prefix      = $install_dir ? 'PREFIX='.$install_dir : '';

## set environment variables ##
require my_lib;
my_lib->import($install_dir);

#sub my_system{ print join( ' ', @_, "\n"); 0 }
sub my_system{ system @_ }

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


sub get_and_install_dist
{
  my $url = shift;
  $url =~ m#.*/((.*)\.tar\.gz)$# or die "can`t parse url '$url'\n";
  my ($fname, $dir) = ($1, $2);

  !-f $fname && my_system($wget, $url)     && die "can`t download file '$url'\n";
  !-d $dir   && my_system(@tar, $fname)    && die "can`t extract file '$fname'\n";
  chdir($dir)                              || die "can`t change directory '$dir'\n";
  my_system($perl, 'Makefile.PL', $prefix) && die "can`t create makefile\n";
  my_system($make)                         && die "make: failed\n";
  my_system($make, 'install')              && die "make install: failed\n";
  chdir('..');
  print "## $dir successfully installed ##\n";
}

sub install_online_cpanm
{
  my $url = 'http://cpanmin.us';
  my $inst_dir = $install_dir ? '-l '.$install_dir : '';
  my_system("$wget_pipe $url | $perl - $inst_dir App::cpanminus") && die "can`t install cpanminus\n";
  print "## cpanminus successfully installed ##\n";
}

sub install_with_cpanm
{
  my $module = shift;
  system('cpanm', '-l', $install_dir, $module) && die "## installation $module failed ##\n";
  print "## $module successfully installed ## \n";
}
