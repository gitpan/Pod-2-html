#!/usr/bin/perl
use strict;
use warnings;

use Pod::2::html;

my $pod = Pod::2::html->new('pod2html.pm');
$pod->template('bar.tmpl');
$pod->readpod(-head1 => "a", -head3 => "c", -item => "d");
