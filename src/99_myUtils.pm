##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.

package main;

use strict;
use warnings;
use utf8;
use Time::HiRes qw(time);

my @globalrecords = ();

sub
myUtils_Initialize($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.

sub printGlobalRecs()
{
  my $recordsCount = @globalrecords;
  return $recordsCount;
}

sub
postMqttSenMl($$$$)
{
	my ($topic, $basename, $name, $value) = @_;

	# Doppelpunkt am ende des Readings entfernen
	$name = (split(":",$name))[0];
	my $time = int( time * 1000);
	
	my @records = ();
	
	my %rec_hash = (
					'bn' => "revpi01:" . $basename . ":", 
					'bt' => $time, 
					'n' => $name, 
					'vs' => $value
				);

	push(@records, \%rec_hash);
	my $payload = JSON->new->utf8(0)->encode(\@records);
	fhem("set Mainflux publish $topic $payload");
}

sub
mqttCommand($$$$)
{
	my ($topic, $name, $devicetopic, $event) = @_;
	
	my $session_id = (split('/', $topic))[-1];
	my $respTopic = $topic;
	$respTopic =~ s/\/req\//\/res\//g;
	my $commands = decode_json $event;
	my $command = "";
	
	for my $hashref (@{$commands}) {
		if($hashref->{n} eq "exec") 
		{
			# print $hashref->{n}."\n";
			# print $hashref->{bn}."\n";
			# print $hashref->{vs}."\n";
			$command = $hashref->{vs};
			my $resp = fhem("$command");
			postMqttSenMl($respTopic, $command, "exec", $resp) if defined $resp;
		}
	}
		
	return { sessionId=>$session_id, command=>$command };
}

1;
