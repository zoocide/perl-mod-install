#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);
use constant bs_dir => catfile($Bin, '..'); #< boostrap.pl directory
use lib bs_dir; #< my_lib.pm

=head1 SYNOPSIS

  # installs example into <install_dir> directory
  ./install.pl <install_dir>

=cut

my $install_dir = $ARGV[0] or die "install directory is not specified\n";

unless (-d $install_dir){
  ## if install directory does not exist, creates it. ##
  -f $install_dir && die "'$install_dir' is not a directory\n";
  mkdir($install_dir) || die "can`t create '$install_dir': $!\n";
}
else{
  ## if install directory exists, ask user, what to do ##
  my $ans;
  while(1) {
    print "Directory '$install_dir' already exists. Install into it anyway? [yes, no]:";
    chomp($ans = <STDIN>);
    $ans =~ s/^\s+|\s+$//g; #< remove beginnig and trailing spaces
    $ans = lc $ans;
    last if $ans eq 'yes' || $ans eq 'no';
    print "Please, enter 'yes' or 'no'.\n";
  }
  die "Installation aborted\n" if $ans eq 'no';
}

## set parameter variables ##
my $src_path = catfile($Bin, 'src');
my $lib_path = catfile($install_dir, 'lib');

## run bootstrap.pl to install required modules ##
my @bs_args = (
  '-I', $Bin,     #< use modules_to_install.pm from $FindBin::Bin directory
  '-I', bs_dir,  #< include bootstrap directory
  catfile(bs_dir, 'bootstrap.pl'),
  $lib_path      #< where to install library
);
system($^X, @bs_args) == 0
  || die "required modules installation failed\n";

## 'use my_lib $lib_path;' to include just installed modules, required for this script ##
require my_lib;
my_lib->import($lib_path);

## 'use File::Copy::Recursive;' is not standart, so it should be installed by bootstrap.pl, executed above ##
require File::Copy::Recursive;
File::Copy::Recursive->import(qw(fcopy rcopy));

## copy my_lib.pm to install directory, to use it later by installed example ##
my @files_to_copy = map catfile(bs_dir, $_), ('my_lib.pm');
fcopy($_, $install_dir) or die "can`t copy '$_' to directory '$install_dir': $!\n" for @files_to_copy;

## copy example source code to install directory ##
rcopy($src_path, $install_dir)   or die "can`t copy source files to directory '$install_dir': $!\n";

print "Installation into '$install_dir' complete\n";
