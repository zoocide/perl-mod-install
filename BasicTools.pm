package BasicTools;
use Config;
use File::Spec::Functions qw(catfile rel2abs path);
use constant windoze => $^O eq 'MSWin32';

# ($protocol, $server, $directory, $filename) = parse_url($url);
sub parse_url
{
  my $url = shift;
  $url =~ m#^(\w+)://(.+?)/(.*/)?(.+)$# || die "can`t parse url $url\n";
  return ($1, $2, $3, $4)
}

# my $fname = BasicTools::download_file_HTTP_Tiny($url, $fname?);
sub download_file_HTTP_Tiny
{
  my ($url, $fname) = @_;

  ## parse url ##
  $fname ||= (parse_url($url))[3];

  ## get head ##
  my $res = HTTP::Tiny->new->head($url);
  $res->{success} || die "can`t get head $url\n";

  ## get content ##
  $res = HTTP::Tiny->new->get($url);
  $res->{success} || die "can`t get $url\n";
  $res->{content} || die "empty content from $url\n";

  ## save file ##
  open my $f, '>', $fname or die "can`t write to file $fname\n";
  binmode $f if 0 <= index($res->{headers}{'content-type'}, 'application');
  print $f $res->{content};
  close $f;
  return $fname
}

# BasicTools::extract_Archive_Extract($filename, $out_directory?);
sub extract_Archive_Extract
{
  my ($fname, $out_dir) = @_;
  $out_dir ||= '.';
  my $ae = Archive::Extract->new( archive => $fname );
  $ae->extract(to => $out_dir) or die $ae->error;
}

# my $bt = BasicTools->new;
sub new
{
  my $class = shift;
  bless {
    make => '',
    tar  => '',
    wget  => '',
    curl  => '',
    perl  => $^X,
    ## my $fname = get_http($url, $fname);
    get_http => sub { die "http client is not set. Please, download '$_[0]' manually.\n" },
    ## extract($file, $out_dir);
    extract  => sub { die "Archiver is not set. Please, extract archive '$_[0]' manually.\n" },
  }, $class;
}

# my $fname = $bt->download($url, $fname?);
sub download
{
  my ($self, $url, $fname) = @_;
  $fname ||= (parse_url($url))[3];
  $self->{get_http}($url, $fname);
}

# $bt->extract($fname, $out_dir?);
sub extract
{
  my ($self, $fname, $dir) = @_;
  $dir ||= '.';
  $self->{extract}($fname, $dir);  
}

# my $full_path = $bt->which($cmd);
sub which
{
  my ($self, $cmd) = @_;
  my $res = $self->m_which($cmd);
  $res || return undef;
  $res =~ /\s/ ? $self->quote($res) : $res;
}

# $bt->set_path(@PATH);
sub set_path
{
  my $self = shift;
  $ENV{PATH} = join $Config{path_sep}, @_
}

# my $quoted_string = $bt->quote($string);
sub quote
{
  my ($self, $str) = @_;
  my $q = windoze ? q/"/ : q/'/;
  ## is quoted? ##
  substr($str, 0, 1) eq $q && substr($str, -1, 1) eq $q && return $str;
  
  $str =~ s/$q/\\$q/g;
  return $q.$str.$q;
}

# $bt->init_tools;
sub init_tools
{
  my $self = shift;

  my $cmd;
  ## detect HTTP client ##
  if ($cmd = $self->which('wget')){
    $self->{wget} = $cmd;
    $self->{get_http} = sub {
      my ($url, $fname) = @_;
      my @opts = ('-O', $fname);
      system($cmd, @opts, $url) == 0 or die "can`t download '$url' with wget.\n";
      $fname
    };
  }
  elsif ($cmd = $self->which('curl')){
    $self->{curl} = $cmd;
    $self->{get_http} = sub {
      my ($url, $fname) = @_;
      my @opts = ('-o', $fname);
      system($cmd, @opts, $url) == 0 or die "can`t download '$url' with curl.\n";
      $fname
    };
  }
  else{
    ## try HTTP::Tiny ##
    eval{ require HTTP::Tiny };
    if (!$@){
      $self->{get_http} = \&download_file_HTTP_Tiny;
    }
  }

  ## detect archiver ##
  if ($cmd = $self->which('tar')){
    $self->{tar} = $cmd;
    $self->{extract} = sub {
      my ($fname, $out_dir) = @_;
      my @opts = ('-x', '-f', $fname, '-C', $out_dir);
      system($cmd, @opts) == 0 or die "can`t extract '$fname' with tar.\n"
    };
  }
  else{
    ## try Archive::Extract ##
    eval{ require Archive::Extract };
    if (!$@){
      $self->{extract} = \&extract_Archive_Extract;
    }
  }

  ## detect make ##
  if ($cmd = $self->which('make')){
    $self->{make} = $cmd;
  }
  elsif ($cmd = $self->which('nmake')){
    $self->{make} = $cmd;
  }
  elsif ($cmd = $self->which('dmake')){
    $self->{make} = $cmd;
  }
}

# my $bool = $bt->has_make;
sub has_make
{
  my $self = shift;
  $self->{make}
}

# $bt->get_dmake($out_dir?);
sub get_dmake
{
  my ($self, $dir) = @_;
  my $url = 'http://search.cpan.org/CPAN/authors/id/S/SH/SHAY/dmake-4.12-20090907-SHAY.zip';
  my $fname = 'dmake.zip';
  $dir ||= '.';
  $fname = $self->download($url, catfile($dir, $fname));
  $self->extract($fname, $dir);
  $self->set_path(rel2abs(catfile($dir, 'dmake')), path());
  $self->{make} = $self->which('dmake') || die "can`t find dmake in path.\n";
}

sub m_which
{
  my ($self, $cmd) = @_;
  my @ext = ('', $Config{_exe}, (windoze ? '.bat' : ()));
  (-X $cmd && !-d $cmd) && return rel2abs($cmd);

  for my $dir (path()){
    for my $ext (@ext){
      my $fpath = rel2abs(catfile($dir, $cmd.$ext));
      return $fpath if -X $fpath && !-d $fpath;
    }
  }
  return undef;
}

1
