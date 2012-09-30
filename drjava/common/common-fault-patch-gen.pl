#!/usr/bin/perl
#
#  Copyright (c) 2009-@year@. The  GUITAR group  at the University of
#  Maryland. Names of owners of this group may be obtained by sending
#  an e-mail to atif@cs.umd.edu
#
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this software and associated documentation files
#  (the "Software"), to deal in the Software without restriction,
#  including without limitation  the rights to use, copy, modify, merge,
#  publish,  distribute, sublicense, and/or sell copies of the Software,
#  and to  permit persons  to whom  the Software  is furnished to do so,
#  subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#  IN NO  EVENT SHALL THE  AUTHORS OR COPYRIGHT  HOLDERS BE LIABLE FOR ANY
#  CLAIM, DAMAGES OR  OTHER LIABILITY,  WHETHER IN AN  ACTION OF CONTRACT,
#  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#
# Compare a source and fault-seeded-source directory
# and generate numbered patche files. Each patch file
# contains only 1 fault.
#

use Cwd;
use Cwd 'abs_path';
use File::Path;
use File::Basename;

# Read command line argument
my $str_src = shift;
my $str_src_fault = shift;
if ((! -e $str_src) || (! -e $str_src_fault)) {
   print "Usage: $0 <src> <src-fault>\n";
   print "<src> or <src-fault> not found\n";
   exit(1);
}
`diff --exclude=.svn --ignore-all-space -U 0 $str_src $str_src_fault > patch`;

my $str_patch_file = "patch";
   $str_patch_file = abs_path($str_patch_file);
if (! -e $str_patch_file) {
   print "patch $str_patch_file not found\n";
   exit(1);
}

# Create output directory
my $str_dir_fault = dirname($str_patch_file);
   $str_dir_fault .= "/fault";
rmtree($str_dir_fault);
mkdir($str_dir_fault);

# Read patch file
open(PATCH, "< $str_patch_file");
my @P = <PATCH>;
close(PATCH);
unlink($str_patch_file);

#
# Parse patch file
#
my $fault_id = 0;

my @H = ();
my $h_lines = 0;

my @SECTION = ();
my $s_lines = 0;

for my $p (@P) {
   # 1. New file header
   if ($p =~ m/^diff/) {
      write_section();
      @H = ();
      $header_in_progress = 1;
   }

   # 2. New diff section header
   if ($p =~ m/^\@\@/ ) {
      write_section();
      $header_in_progress = 0;
   }

   if ($header_in_progress eq 1) { 
      $H[ $h_lines++ ] = $p;
   } else{
      $SECTION[ $s_lines++ ] = $p;
   }
}

# Last section
write_section();
exit(0);


#
# Write one fault section as a complete patch file
#
sub
write_section
{
    if ($s_lines > 0) {
      my $str_fault_file = $str_dir_fault."/$fault_id";
      $fault_id++;

      open (FAULT, "> $str_fault_file");
      print FAULT @H;
      print FAULT @SECTION;
      close(FAULT);

      @SECTION = ();
      $s_lines = 0;
   }
}

