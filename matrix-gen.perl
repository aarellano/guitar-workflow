#!/usr/bin/perl

use XML::Simple;
use File::Basename;

my $SCRIPT_PATH = dirname(__FILE__);
my $simple = XML::Simple->new (ForceArray => 1, KeepRoot => 1);

$COBERTURA_REPORTS=$SCRIPT_PATH . '/cobertura-reports/';
$MATRIX_FILE=$SCRIPT_PATH . '/reports/html/matrix.html';
$table = '<table border="1">';

opendir(my $dh, $COBERTURA_REPORTS) || die;
unlink $MATRIX_FILE;
open(my $fh, '>>', $MATRIX_FILE) || die;

print $fh '<html><head><title>Coverage matrix</title></head><body>';

$first_row = 1;

while(readdir $dh) {

	if ($_ ne '.' && $_ ne '..') {

		$path = $COBERTURA_REPORTS . "$_";
		my $data = $simple->XMLin($path);
		$class = $data->{coverage}->[0]->{packages}->[0]->{package}->{''}->{classes}->[0]->{class};

		if ($first_row) {
			$table .= '<tr><th rowspan=2>Class/Line/Testcase</th>';
			foreach $k (keys %$class)
			{
				$colspan = 0;
				foreach $l (@{$class->{$k}->{lines}->[0]->{line}}) {
					$lines_row .= '<th>' . $l->{number} . '</th>';
					$colspan++;
				}

				$table .= '<th colspan=' . $colspan . '>' . $k . '</th>';
			}
			$first_row = 0;
			$table .= '<tr>' . $lines_row . '</tr>'
		}

		$table .= '<tr><td>' . $_ . '</td>';
		foreach $k (keys %$class)
		{
			foreach $l (@{$class->{$k}->{lines}->[0]->{line}}) {
				$table .= '<td>' . $l->{hits} . '</td>';
			}
		}
		$table .= '</tr>';

	}
}
closedir $dh;

print $fh '</table></body></html>';
print $fh $table;
close $fh;
