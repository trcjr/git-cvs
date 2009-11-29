#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";
use MyTest::Dirs;
use MyTest::Replay;

use Test::More tests => 2;

# Do a 'git reset --hard master' instead of 'git reset --hard cvs/cvshead'
# This test fails.

# Define some directories
my %D = MyTest::Dirs->hash(
    data => [],
    temp => [cvs_repo => 'cvs',
             cvs_work => 'cvs_work',
             git_repo => 'git'],
);

my $cvs_module = 'module1';

# Create a cvs repo and working dir
my $cvs = MyTest::Replay::CVS->new(path => $D{cvs_work},
                                   module => $cvs_module,
                                   cvsroot => $D{cvs_repo});

$cvs->playback(<<ACTIONS);
## Check in a couple of files
+one
+two 
*cvs add one two
*cvs ci -m "added one and two"
ACTIONS

# Create a git repo, which explicitly uses our dist's git cvs
my $git = MyTest::Replay::Git->new(path => $D{git_repo},
                                   exe_map => {
                                       'git-cvs' => "$Bin/../bin/git-cvs",
                                   });


$git->playback(<<ACTIONS);
## Init .git-cvs and make the first import from CVS
+.git-cvs cvsroot=$D{cvs_repo}
+.git-cvs cvsmodule=$cvs_module

*git-cvs pull
?one
?two

## set the default log format (this is the earliest we can do that)
##*git config format.pretty %h=%s%d%n
ACTIONS

$git->playback(<<ACTIONS);
## Now add a file in git
+alpha
*git add alpha
*git commit -m "added alpha" 
*git log --graph  --all

*git-cvs push
*git log --graph --all

*git-cvs pull 
*git reset --hard master
*git log --graph --all
ACTIONS

$git->playback(<<ACTIONS);
+beta
*git add beta
*git commit -m "added beta" 
*git log --graph --all

*git-cvs push
ACTIONS

__END__
