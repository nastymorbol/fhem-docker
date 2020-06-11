##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.

package main;

use strict;
use warnings;
use utf8;
use Data::Dumper;
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
	# Send to ALL MQTT Clients ....
	fhem("set TYPE=MQTT2_CLIENT publish $topic $payload");
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
		
	return { sessionId=>$session_id, command=>$command, state=>FmtDateTime(time()) };
}

# ------------ START COMMAND CLI -------------

sub
mqttCliCommand($$$$)
{
	my ($topic, $name, $devicetopic, $event) = @_;
			
	# Die lezten beiden Parts des Topics sind die Session und Command id
	my $session_id = join("/", (split('/', $topic))[-2,-1] );
	my $respTopic = "command/res/$session_id";   #$topic;
		
	#print("MQQT_CMD TOPIC: $topic\n");
	#print("MQQT_CMD EVENT: $event\n");
		
	my $request = eval { decode_json($event) };
	if ($@)
	{
		return { sessionId=>$session_id, error=>$@, state=>"Error " . FmtDateTime(time()) };
	}
	
	# Requests mit dem Ziel FHEM Enviroment
	if(not exists($request->{type}))
	{
		return { sessionId=>$session_id, error=>"Command has no type field", state=>"Error " . FmtDateTime(time()) };
	}
	
	# ToDo: Prüfen ob Version passt
	if($request->{type} eq "env")
	{
	
		my $response = buildBasicResponse($request);
		$response->{ts_req} = unixTimeMs();

		executeResponseCommands($response);

		if($request->{ts})
		{
#			$response->{ts_req} = $request->{ts};
			$response->{ts_res} = unixTimeMs();
		}
		
		my $payload = JSON->new->utf8(0)->encode($response);
#		fhem("trigger $name MQTT_CMD: " . $payload );

		# Direct call to MQTT2 Clients
		postMqttPayload($respTopic, $payload);
		
#		print("-----------------------------------------\n" );
#		print("--- CMD LENGT " . length($fhemCmd) . "  ---------\n" );

		return { payload=>length($payload), sessionId=>$session_id, error=>"", state=>"OK " . FmtDateTime(time()) };
	}
			
	return { sessionId=>$session_id, error=>"Command Type $request->{type} not valid", state=>"Error " . FmtDateTime(time()) };
}

sub
executeResponseCommands(@)
{
	my $response = $_[0];
	
	$response->{ver} = "1.0";
	
	# Commands ausführen wenn vorhanden
	if($response->{commands})
	{				
		while ( my ($key, $value) = each( @{$response->{commands}} ) ) 
		{
			my $cmd = $value->{name};

			# ToDo: Prüfen ob ein Fehler auftritt eval?
			my $exec = fhem("$cmd");
			
			# Try to decode as json Resonse
			my $jsonres = eval { decode_json($exec) };
			if ($@)
			{
				#fhem("trigger MqttCli MQTT_CMD: " . Dumper $exec );
				$value->{resp} = $exec;		
			}
			else {
				#fhem("trigger MqttCli MQTT_CMD: " . Dumper $jsonres  );
				$value->{resp} = $jsonres;
			}
		}
	}
	else
	{
		# Keine Commandos definiert - PING request
		$response->{resp} = {
			ping => unixTimeMs()
		}
	}

	
	return 0;
}

sub
buildBasicResponse
{	
	my $request = $_[0];
	
	my $response = {};
	$response->{type} = $request->{type};;	
	
	# ToDo: Doppelte Kommandos entfernen
	if($request->{command})
	{
		$response->{commands} = ();
		push(@{$response->{commands}}, buildResponseCommand($request->{command}));
	}
	
	if($request->{commands})
	{
		$response->{commands} = () unless($response->{commands});
		
		while ( my ($key, $value) = each( @{$request->{commands}} ) ) 
		{
			push(@{$response->{commands}}, buildResponseCommand($value));
		}
	}

	return $response;
}

sub
buildResponseCommand($)
{
	return {
		name => shift,
		resp => undef
	};
}

sub
unixTimeMs()
{
	return int( time * 1000 );
}

# ------------ END COMMAND CLI ---------------

# ============================================
# ------------ START MQTT HELPER -------------

sub
postMqttPayload($$)
{
	my ($subChannel, $payload) = @_;
	
	my $channel = getGatewayChannel($subChannel);
	return undef unless $channel;
	
	# Direct call to MQTT2 Clients
	foreach my $dev (devspec2array("TYPE=MQTT2_CLIENT")) {
		next unless $dev;		
		#print( Dumper $defs{$dev} );
		
		MQTT2_CLIENT_doPublish($defs{$dev}, $channel, $payload, 0);
	}
}

sub
getGatewayChannel($)
{
	# DeviceId -> Die DeviceID ist auch die ClientId des MQQT_CLIENT
	
	my $clientId = getClientId();		
	if($clientId)
	{
		my $subChannel = shift;
		if($subChannel)
		{
			my $channel = "gateway/$clientId/$subChannel";
			$channel =~ s/\/{2}/\//g;
			#print( "MQTT_CLIENT CLIENTID: " . Dumper "$channel" );
			return "$channel";
		}
		#print( "MQTT_CLIENT CLIENTID: " . Dumper "gateway/$clientId" );
		return "gateway/$clientId";
	}
	
	return undef;
}

sub
getClientId()
{
	foreach my $dev (devspec2array("TYPE=MQTT2_CLIENT")) 
	{
		next unless $dev;
		my $clientId = $attr{MqttClient}->{clientId};		
		if($clientId)
		{
			return $clientId;
		}
	}
	return undef;
}

# ------------ END MQTT HELPER ---------------





1;