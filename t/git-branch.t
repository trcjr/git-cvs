#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";
use MyTest::Dirs;
use MyTest::Replay;

use Test::More tests => 8;

#
# This tests branches on the git side
#

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

## Now create a branch in git and add file on that branch
*git branch test-branch
*git checkout test-branch
+test-branch-file
*git add test-branch-file
*git commit -m "Added test-branch-file"

## Now back to master and add a file on master
*git checkout master
!test-branch-file
+three
*git add three
*git commit -m "added three" 

## Veryify we can sync at this point
*git-cvs push
*git-cvs pull
*git reset --hard cvs/cvshead

## Merge
*git merge test-branch
?test-branch-file

## And synch again
*git-cvs push
*git-cvs pull
*git reset --hard cvs/cvshead

## Same thing but do not sync before merge
## Add new file on master
+four
*git add four
*git commit -m "added four"

## Add new file on branch
*git checkout test-branch
!four
+test-branch-file-2
*git add test-branch-file-2
*git commit -m "Added test-branch-file-2"

## Make to master and merge
*git checkout master
?four
!test-branch-file-2
*git merge test-branch
?test-branch-file-2

## And sync new merge
*git-cvs push
*git-cvs pull
*git reset --hard cvs/cvshead

ACTIONS

