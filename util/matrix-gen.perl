#!/usr/bin/perl

use XML::Simple;
use File::Basename;
use File::Path qw(make_path);

my $script_path = dirname(__FILE__);
my $simple = XML::Simple->new (ForceArray => 1, KeepRoot => 1);

$cobertura_report_file=$script_path . '/cobertura-reports/coverage.xml';
make_path('reports/html');
$matrix_file=$script_path . '/reports/html/matrix.html';
$table = '<table border="1">';

$first_row = 0;
$last_row = 0;

if (@ARGV[0] == 0) {
	unlink $matrix_file;
	$first_row = 1;
} elsif (@ARGV[0] == 2)
	$last_row = 1;

open(my $fh, '>>', $matrix_file) || die;

print $fh '<html><head><title>Coverage matrix</title></head><body>';

my $data = $simple->XMLin($cobertura_report_file);
$package = $data->{coverage}->[0]->{packages}->[0]->{package};
if ($first_row) {
	$table .= '<tr><th rowspan=2>Class/Line/Testcase</th>';
	foreach $p (keys %$package)
	{
		foreach $c (@{$package->{$p}->{classes}})
		{
			$class = $c->{class};
			foreach $k (keys %$class)
			{
				$colspan = 0;
				foreach $l (@{$class->{$k}->{lines}->[0]->{line}}) {
					$lines_row .= '<th>' . $l->{number} . '</th>';
					$colspan++;
				}

				$table .= '<th colspan=' . $colspan . '>' . $k . '</th>';
			}
		}
	}
	$table .= '<tr>' . $lines_row . '</tr>'
}

$table .= '<tr><td>' . $_ . '</td>';

foreach $p (keys %$package)
{
	foreach $c (@{$package->{$p}->{classes}})
	{
		$class = $c->{class};
		foreach $k (keys %$class)
		{
			foreach $l (@{$class->{$k}->{lines}->[0]->{line}}) {
				$table .= '<td>' . $l->{hits} . '</td>';
			}
		}
	}
}
$table .= '</tr>';

print $fh '</table></body></html>';
print $fh $table;
close $fh;
