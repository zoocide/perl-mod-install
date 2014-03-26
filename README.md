perl-mod-install
================

Allows to install all required Perl modules for your project.

Usage:

1. put all desired modules into file modules_to_install.pm.
2. run "bootstrap.pl \<lib_dir>" to install all modules to \<lib_dir>.
3. Maybe, it will require to put "use lib 'path/to/my_lib.pm'".
4. put "use my_lib 'path/to/\<lib_dir>';" into your script.
