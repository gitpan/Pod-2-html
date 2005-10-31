package Pod::2::html;

use 5.008004;
use strict;
use warnings;

require Exporter;

our %EXPORT_TAGS = ( 'all' => [ qw(
	new template readpod
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	new template readpod
);

our $VERSION = '0.5';

my ($in, $over, $for, $begin, $tmp, $invisible) = 0;
my %option;

sub new {
        my $class = shift;
        my $script = shift;
        my $self = {};
        open(PL, "<$script") || die "Could not open $script: $!";
        $self->{"script"} = [ <PL> ];
        close(PL);
        $self->{"count"} = 0;
        bless $self, $class;
        return $self;
}

sub template {
        my $self = shift;
        my $template = shift || 0;
        open(TMPL, "<$template") || die "Could not open $template: $!";
        $self->{"data"} = [ <TMPL> ];
        close(TMPL);
        foreach(@{ $self->{"data"} }) {
                if(/\s?\<main\>\s?/i) {
                        $self->{"status"} = 1;
                }
        }
        die "The <main> Tag is missing in $template" unless $self->{"status"};
}

sub readpod {
        my $self= shift;
        %option = @_;
	$self->{"end"} = 0;
        $self->{"in"} = 0;
        foreach(@{ $self->{"script"} }) {
                if(m/^=(.*)/ && $1 !~ /cut/) {
                        $self->{"in"} = 1;
                        push @{ $self->{"pod"} }, $_;
                } elsif(m/^=cut\s+/) {
                        $self->{"in"} = 0;
                } elsif($self->{"in"}) {
                        push @{ $self->{"pod"} }, $_;
                }
        }
        foreach(@{ $self->{"data"} }) {
		if(m/(.*?)\<main\>(.*?)/i) {
			print $1 . "\n<pre>\n";
			foreach(@{ $self->{"pod"} }) {
                		&_parsepod($_);
        		}
			print $2 . "\n</pre>\n";
		} else {
			print $_;
		}
	}
}

sub _parsepod {
        my $line = shift;
        $line =~ s/B\<(.*?)\>/\<b\>$1\<\/b\>/gi;
        $line =~ s/I\<(.*?)\>/\<i\>$1\<\/i\>/gi;
        $line =~ s/U\<(.*?)\>/\<u\>$1\<\/u\>/gi;
	if($line =~ m/^=head(\d+)\s+(.*)/) {
                $tmp = $1*20-20;
		if($option{"-head$1"}) {
			print "<h$1 class=\"";
			$tmp = $option{"-head$1"};
			print "$tmp\">$2</h$1>\n";
		} else {
			print "<h$1 style=\"margin-left:$tmp;\">$2</h$1>\n";
		}
        } elsif($line !~ m/^=.*/ && $in == 0) {
		unless($invisible) {
                	print $line . "<br>" if $line =~ m/\S+/;
		}
        } elsif($line =~ m/^=over\s+?(\d+)/) {
                $in = 1;
                $over = $1*3;
                if($option{"-over"}) {
			print "<ul class=\"";
			print $option{"-over"};
			print "\">\n";
		} else {
			print "<ul>\n";
		}
        } elsif($in) {
                if($line =~ m/^=item\s+(?:\*\s+)?(.*)/) {
                        print "<li style=\"margin-left: ${over}px;\">$1</li>\n";
                } elsif($line =~ m/^=back/) {
                        print "</ul>\n";
                        $in = 0;
                } elsif($line !~ m/^=.*/) {
			print $line;
		}
        } elsif($line =~ m/^=for\s+(.*)/) {
		$for = 1;
		$invisible = 1 if $1 !~ m/html/;
	} elsif($for) {
		if($line !~ m/^=.*/) {
			print $line . "\n" unless($invisible);
		} elsif($line =~ m/^=begin\s+html/) {
			print "<br>\n" unless($invisible);
		} elsif($line =~ m/^=end\s+.*/) {
			$for = 0;
			$invisible = 0 if($invisible);
		}
	} elsif($line =~ m/^=item\s+(.*)/ && not $in) {
		if($option{"-item"}) {
			print "<h3 class=\"".$option{"-item"}.">$1</h3>\n";
		} else {	
			print "<h3>$1</h3>\n";
		}
	} 
}

1;

__END__

=head1 NAME

Pod::2::html - Convert POD Documentations into HTML files, using a template

=head1 SYNOPSIS

  use Pod::2::html;
  my $pod = pod2html->new('/usr/bin/foo.pl');
  $pod->template('bar.tmpl');
  $pod->readpod(-head1 => "a", -head3 => "c", -text => "b");

=head1 DESCRIPTION

You can create a HTML file, out of POD Documentations, using a HTML template.
In some parts, you can specify a CSS class with a switch in the readpod() Method.

$pod->readpod(-head1 => "a");

specified the CSS class "a" for the POD - part "head1".
The Following CSS parts are availabl in this Version:

=over 4

=item -head(\d+): Every head part is usable. The HTML Tag is h(\d+)

=item -over: The -over option uses the HTML tag ul fpr listings

=item -item: The -item Option is using the h3 Tag for subroutine Documentation

=back

In the template file, you created, a tag named <main> must exist.
This tag will be replaced with the documentation, created of the POD parts in the script.

=head1 AUTHOR

Ingo Walz, <lt>ingo@perl-tutor.de<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Ingo Walz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
