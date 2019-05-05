#!/usr/bin/perl
use strict;
use warnings;

use HTTP::Daemon;
use HTTP::Status;

use JSON;

use constant SILENT => 1;

$SIG{INT} = \&signal_handler;
$SIG{TERM} = \&signal_handler;

# Read command line arguments
my $PORT = commandline('p', 9999);

# Set MEMORY_FILE based on PORT
my $MEMORY_FILE = "/tmp/embot_memory_${PORT}.txt";

my %memory;
restore();

my $d = HTTP::Daemon->new(
	LocalPort => $PORT,
	Reuse => 1
) || die;
print "Please contact me at: <URL:", $d->url, ">\n";
print "Process id: <ID:", $$, ">\n";

while (my $c = $d->accept) {
	while (my $r = $c->get_request) {
		if ($r->method eq 'GET' and $r->uri->path eq "/json") {

			my %query = $r->uri->query_form;
			my $sid = $query{'sid'} || 'localuser';

			my $reply = '{}';
			if (defined $memory{$sid}) {
				$reply = encode_json $memory{$sid};
			}

			# Generate HTML response
			my $response = HTTP::Response->new(200, 'OK');
			$response->header('Content-Type' => 'application/json; charset=utf-8');
			$response->header('Connection' => 'close');
			$response->content($reply);

			$c->send_response($response);

		} elsif ($r->method eq 'GET' and $r->uri->path eq "/get") {

			my %query = $r->uri->query_form;
			my $sid = $query{'sid'} || 'localuser';
			my $key = $query{'key'};
			my $del = $query{'once'};

			my $reply = 'undefined';
			if (defined $key && defined $memory{$sid}{$key}) {
				print "Get $sid <$key>\n" unless (SILENT);
				$reply = $memory{$sid}{$key};

				if (defined $del && $del eq 'true') {
					print "Delete $sid <$key>\n" unless (SILENT);
					delete $memory{$sid}{$key};
				}
			}

			# Generate HTML response
			my $response = HTTP::Response->new(200, 'OK');
			$response->header('Content-Type' => 'text/html; charset=utf-8');
			$response->header('Connection' => 'close');
			$response->content($reply);

			$c->send_response($response);

		} elsif ($r->method eq 'GET' and $r->uri->path eq "/set") {
			# remember, this is *not* recommended practice :-)
			#$c->send_file_response("/etc/passwd");

			my %query = $r->uri->query_form;
			my $sid = $query{'sid'} || 'localuser';
			my $key = $query{'key'};
			my $val = $query{'val'};

			if (defined $key && defined $val) {
				print time(), " Setting $sid <$key=$val>\n" unless (SILENT);
				$memory{$sid}{$key} = $val;
			}

			# Generate HTML response
			my $response = HTTP::Response->new(200, 'OK');
			$response->header('Content-Type' => 'text/html; charset=utf-8');
			$response->header('Connection' => 'close');
			$response->content('OK');

			$c->send_response($response);
		} elsif ($r->method eq 'GET' and $r->uri->path eq "/setMany") {

			my %query = $r->uri->query_form;
			my $sid = $query{'sid'} || 'localuser';

			my $i=1;
			while ($i<10) {
				#print "loop $i\n";
				my $key = $query{'key' . $i};
				my $val = $query{'val' . $i};

				last unless (defined $key && defined $val);

				print time(), " Many Setting $sid <$key=$val>\n" unless (SILENT);
				$memory{$sid}{$key} = $val;
				$i++;
			}

			# Generate HTML response
			my $response = HTTP::Response->new(200, 'OK');
			$response->header('Content-Type' => 'text/html');
			$response->header('Connection' => 'close');
			$response->content('OK');

			$c->send_response($response);
		} elsif ($r->method eq 'POST' and $r->uri->path eq "/setManyJSON") {
			#print $r->content, "\n";

			my %query = %{ decode_json $r->content };
			my $sid = $query{'sid'} || 'localuser';

			my $i=1;
			while ($i<10) {
				#print "loop $i\n";
				my $key = $query{'key' . $i};
				my $val = $query{'val' . $i};

				last unless (defined $key && defined $val);

				print time(), " Many Setting $sid <$key=$val>\n" unless (SILENT);
				$memory{$sid}{$key} = $val;
				$i++;
			}

			# Generate HTML response
			my $response = HTTP::Response->new(200, 'OK');
			$response->header('Content-Type' => 'text/html');
			$response->header('Connection' => 'close');
			$response->content('OK');

			$c->send_response($response);
		} elsif ($r->method eq 'GET' and $r->uri->path eq "/incr") {

			my %query = $r->uri->query_form;
			my $sid = $query{'sid'} || 'localuser';
			my $key = $query{'key'};

			my $reply = 0;
			if (defined $key && defined $memory{$sid}{$key} && $memory{$sid}{$key} =~ m/^\d+$/) {
				$reply = $memory{$sid}{$key} + 1;
			}

			print time(), " Count $sid <$key=$reply>\n" unless (SILENT);
			$memory{$sid}{$key} = $reply;

			# Generate HTML response
			my $response = HTTP::Response->new(200, 'OK');
			$response->header('Content-Type' => 'text/html');
			$response->header('Connection' => 'close');
			$response->content($reply);

			$c->send_response($response);
		} elsif ($r->method eq 'GET' and $r->uri->path eq "/delete") {

			my %query = $r->uri->query_form;
			my $sid = $query{'sid'} || 'localuser';
			my $key = $query{'key'};

			#my $reply = 'undefined';
			if (defined $key && defined $memory{$sid}{$key}) {
				#$reply = $memory{$sid}{$key};
				print "Delete $sid <$key>\n" unless (SILENT);
				delete $memory{$sid}{$key};
			}

			# Generate HTML response
			my $response = HTTP::Response->new(200, 'OK');
			$response->header('Content-Type' => 'text/html');
			$response->header('Connection' => 'close');
			$response->content('OK');

			$c->send_response($response);
		} elsif ($r->method eq 'GET' and $r->uri->path eq "/reset") {
			my %query = $r->uri->query_form;
			my $sid = $query{'sid'} || 'undefined';

			if (defined $memory{$sid}) {
				print "Delete user $sid\n";
				delete $memory{$sid};
			} elsif ($sid eq 'all') {
				print "Reset memory\n";
				%memory = (); # empty
			}

			# Generate HTML response
			my $response = HTTP::Response->new(200, 'OK');
			$response->header('Content-Type' => 'text/html');
			$response->header('Connection' => 'close');
			$response->content('ok');

			$c->send_response($response);

		} else {
			$c->send_error(RC_FORBIDDEN)
		}
	}
	$c->close;
	undef($c);
}

sub signal_handler {
	my $filename = $MEMORY_FILE;
	open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
	foreach my $sid (keys %memory) {
		foreach my $key (keys $memory{$sid}) {
			print $fh $sid, "\t", $key, "\t", $memory{$sid}{$key}, "\n";
		}
	}
	close $fh;

	die "Caught a signal $!";
}

sub restore {
	# Restore memory
	my $filename = $MEMORY_FILE;
	open(my $fh, $filename) or do {warn "Could not open file '$filename' $!"; return;}; #die "Could not open file '$filename' $!";
	while(<$fh>) {
		chomp $_;
		my($sid, $key, $val) = split /\t/, $_, 3;
		print "Reading $sid <$key=$val>\n" unless (SILENT);
		$memory{$sid}{$key} = $val;
	}
	close $fh;
}

sub commandline {
	my($command, $default) = @_;
	my $i = 0;
	while ($i < @ARGV+0) {
		#print $ARGV[$i], "\n";
		if ($ARGV[$i] =~ m/^\-([a-z])(.*)/) {
			die "Unspecified parameter '$1'" if $2 eq '';
			#print "$1=$2\n";
			return $2 if ($1 eq $command);
		}
		$i++;
	}
	return $default;
}
