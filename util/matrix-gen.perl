#!/usr/bin/perl

use XML::Simple;
use File::Basename;
use File::Path qw(make_path);

my $script_path = dirname(__FILE__);
my $simple = XML::Simple->new (ForceArray => 1, KeepRoot => 1);

$cobertura_reports=$script_path . '/cobertura-reports/';
make_path('reports/html');
$matrix_file=$script_path . '/reports/html/matrix.html';
$table = '<table border="1">';

opendir(my $dh, $cobertura_reports) || die;
unlink $matrix_file;
open(my $fh, '>>', $matrix_file) || die;

print $fh '<html><head><title>Coverage matrix</title></head><body>';

$first_row = 1;

while(readdir $dh) {

	if ($_ ne '.' && $_ ne '..') {

		$path = $cobertura_reports . "$_";
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
