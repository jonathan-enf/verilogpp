#!/usr/bin/perl -w
# A file-driven regression test for verilogpp.
#
# Iterates through a set of test files (named *.vpp) and regenerates
# each.  The original .vpp then becomes the expected data that is
# compared against the regenerated data.
#
# Copyright 2017 Google Inc.
# Author: jonmayer@google.com (Jonathan Mayer)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# Limitations under the License.
#
# This is not an official Google product.

use strict;
use Cwd 'abs_path';
use Test::More;
use File::Basename;
use lib File::Basename::dirname(abs_path($0));
use File::Temp qw/ tempfile /;
use test_utils;
use Getopt::Long;

my $update = 0;
GetOptions("update" => \$update);

my $expected_tests = 0;

# ensure that verilogpp is where we expect it to be:
my $VPP = $ENV{'VPP'} || "../verilogpp";
print "vpp: $VPP\n";
ok(-e $VPP, "verilogpp exists");
$expected_tests++;

# run the preprocessor over everything in the test files directory:
my @testfiles = glob(q(./*.vpp));
print("argv len = $#ARGV\n");
if ($#ARGV > -1) {
  @testfiles = @ARGV;
}
print "Running ",join(" ", @testfiles),"\n";
my $rc = system($VPP,
                "--quieter",
                "-r",
                "--config=./verilogpp.fortest.rc",
                "--incdir", "./subdir",
                "--incdir", "./notasubdir",
                "--incdir", ".",
                @testfiles);
# we don't check return codes as some test files are expected to fail.

sub DiffFiles($$) {
  my $expected = shift;
  my $actual = shift;
  $expected_tests += 2;
  ok(-e $actual, "$actual exists");
  my $rc = system("diff -c ${actual} ${expected}");
  is($rc, 0, "Actual $actual matches expected $expected");
  if ($rc == 0) {
    # clean up
    unlink($actual);
  } elsif ($update) {
    print("Updated ${expected}");
    system("mv -f ${actual} ${expected}");
  }
}

sub VerifyFile($) {
  $expected_tests += 1;  # this method adds 3 checks.
  my $infile = shift;
  my $outfile = $infile;
  $outfile =~ s/.vpp$/.v/;
  isnt($infile, $outfile, "$outfile named appropriately");
  DiffFiles($infile, $outfile);
}

sub VerifyManifest() {
  DiffFiles("./preproc.manifest.expected", "./preproc.manifest");
  unlink("./preproc.manifest");
}

# invoke the preprocessor on these files:
foreach my $testfile (@testfiles) {
  print "-------\n";
  VerifyFile($testfile);
}

VerifyManifest();

done_testing($expected_tests);
