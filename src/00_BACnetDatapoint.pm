##############################################
# $Id: 98_dummy.pm 16965 2018-07-09 07:59:58Z rudolfkoenig $
package main;

use strict;
use warnings;
use SetExtensions;
use Scalar::Util qw(looks_like_number);

sub
BACnetDatapoint_Initialize($)
{
  my ($hash) = @_;

  $hash->{GetFn}     = "BACnetDatapoint_Get";
  $hash->{SetFn}     = "BACnetDatapoint_Set";
  $hash->{DefFn}     = "BACnetDatapoint_Define";
  $hash->{AttrList}  = "readingList " .
                       "disable disabledForIntervals " .
                       "pollIntervall " .
                       $readingFnAttributes;  
}

###################################
sub
BACnetDatapoint_Get($$$)
{
  my ( $hash, $name, $opt, @args ) = @_;

	return "\"get $name\" needs at least one argument" unless(defined($opt));

  # CMD: Get Notification Classes
  if($opt eq "allProperties")
  {    
    readingsSingleUpdate($hash,"state", "CMD:Get All Properties",1);
    return undef;
  }

  # CMD: Get Alarm Summary (Request)
  elsif($opt eq "alarmSummary")
  {    
    readingsSingleUpdate($hash,"state", "CMD:Get Alarm Summary",1);
    return undef;
  }

  # CMD: Get Object List (Request)
  elsif($opt eq "objectList")
  {    
    readingsSingleUpdate($hash,"state", "CMD:Get Object List",1);
    return undef;
  }

  return "unknown argument choose one of allProperties:noArg";
}

###################################
sub
BACnetDatapoint_Set($$)
{
  my ($hash, @a) = @_;
  my $name = shift @a;

  return "no set value specified" if(int(@a) < 1);
  
  my $cmd = shift @a;  

  if($cmd =~ /lowLimit|highLimit|presentValue|covIncrement/)
  {
    my $value = shift @a;
    readingsSingleUpdate($hash, "state", "Write Property $cmd -> $value", 1);
    readingsSingleUpdate($hash, "prop_" . $cmd, $value, 1);
    readingsSingleUpdate($hash, $cmd, $value, 1);
    return undef;
  }
  elsif($cmd =~ /outOfService|alarmValue/)
  {
    my $value = shift @a;
    readingsSingleUpdate($hash, "state", "Write Property $cmd -> $value", 1);
    readingsSingleUpdate($hash, "prop_" . $cmd, $value, 1);
    readingsSingleUpdate($hash, $cmd, $value, 1);
    return undef;
  }
  elsif($cmd eq "limitEnable")
  {
    my $value = shift @a;
    my $le = "";

    readingsSingleUpdate($hash, "state", "Write Property $cmd -> $value", 1);

    if($value =~ /low-limit/) 
    {
      $le .= "1";
    }
    else
    {
      $le .= "0";
    }

    if($value =~ /high-limit/) 
    {
      $le .= "1";
    }
    else
    {
      $le .= "0";
    }

    readingsSingleUpdate($hash, "prop_" . $cmd, $le, 1);
    readingsSingleUpdate($hash, $cmd, $value, 1);
    return undef;
  }

  my @setList = ();

  push @setList, "outOfService:uzsuToggle,True,False";

  if($hash->{ObjectType} =~ /AI|AV|AO/) 
  {      
    push @setList, "limitEnable:multiple-strict,low-limit,high-limit";
    push @setList, "covIncrement:slider,0,0.1,20,1";
    push @setList, "lowLimit:slider,-100,1,100,1";
    push @setList, "highLimit:slider,-100,1,100,1";
    push @setList, "presentValue:slider,-100,1,100,1";
  }
  elsif($hash->{ObjectType} =~ /BI|BV|BO/) 
  {      
    push @setList, "presentValue:uzsuToggle,True,False";
    push @setList, "alarmValue:uzsuToggle,True,False";
  }

  return join ' ', @setList;
  
  return undef;
}

sub
BACnetDatapoint_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);
  

#  Log3 $hash, 1, "Get irgendwas " . join(" ", @{$a}) . " -> " . @{$a};
  return "Wrong syntax: use define <name> BACnetDatapoint BACnetDevice ObjectId" if(int(@a) != 4);

  my $name = shift @a;
  my $type = shift @a;
  my $deviceName = shift @a;
  my $objectId = shift @a;

  my $dev_hash = $defs{$deviceName};

  return "Unknown BACnetDevice $deviceName. Please define BACnetDevice" until($dev_hash);

  $hash->{IODev} = $deviceName;
  $hash->{ObjectId} = $objectId;
  $hash->{IP} = $dev_hash->{IP};

  return "Unknown BACnetInstance in ObjectId $objectId. Please set ID:INSTANCE" if( index($objectId, ':') == -1 );
  return "Unknown BACnetObjectType in ObjectId $objectId. Please set ID:INSTANCE" if( index($objectId, ':') == -1 );

  my ($type, $instance) = split ':', $objectId;

  return "Unknown BACnetObjectInstance in ObjectId $objectId. Please set ID:INSTANCE" until( looks_like_number($instance) );

  $hash->{Intance} = $instance;
  $hash->{ObjectType} = $type;

  #$attr{$name}{registrationIntervall} = 300 unless( AttrVal($name,"registrationIntervall",undef) );
  
  if(AttrVal($name,"room",undef)) {
    
  } else {
#    $attr{$name}{room} = 'BACnet,BACnet->Datapoints->' . $dev_hash->{Instance} . '->' . $hash->{ObjectId} . ',BACnet->Datapoints->' . $dev_hash->{Instance};
    $attr{$name}{room} = 'BACnet,BACnet->Datapoints->' . $dev_hash->{Instance};
  }
  
  readingsSingleUpdate($hash,"state", "defined",1);
    
  return undef;
}

1;

=pod
=item BACnet
=item summary    BACnetDatapoint
=item summary_DE BACnetDatapoint Ger&auml;t
=begin html

<a name="BACnetDatapoint"></a>
<h3>BACnetDatapoint</h3>
<ul>

  Define a BACnetDatapoint. A BACnetDatapoint can take via <a href="#set">set</a> any values.
  Used for programming.
  <br><br>

  <a name="dummydefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; dummy</code>
    <br><br>

    Example:
    <ul>
      <code>define myvar BACnetDatapoint BACnetDevice ObjectId</code><br>
      <code>set myvar 7</code><br>
    </ul>
  </ul>
  <br>

  <a name="dummyset"></a>
  <b>Set</b>
  <ul>
    <code>set &lt;name&gt; &lt;value&gt</code><br>
    Set any value.
  </ul>
  <br>

  <a name="dummyget"></a>
  <b>Get</b> <ul>N/A</ul><br>

  <a name="dummyattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#disable">disable</a></li>
    <li><a href="#disabledForIntervals">disabledForIntervals</a></li>
    <li><a name="readingList">readingList</a><br>
      Space separated list of readings, which will be set, if the first
      argument of the set command matches one of them.</li>

    <li><a name="setList">setList</a><br>
      Space separated list of commands, which will be returned upon "set name
      ?", so the FHEMWEB frontend can construct a dropdown and offer on/off
      switches. Example: attr dummyName setList on off </li>

    <li><a name="useSetExtensions">useSetExtensions</a><br>
      If set, and setList contains on and off, then the
      <a href="#setExtensions">set extensions</a> are supported.
      In this case no arbitrary set commands are accepted, only the setList and
      the set exensions commands.</li>

    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>

</ul>

=end html

=begin html_DE

<a name="BACnetDatapoint"></a>
<h3>BACnetDatapoint</h3>
<ul>

  Definiert eine BACnetDatapoint Instanz
  <br><br>

  <a name="BACnetDatapointdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; BACnetDatapoint BACnetDevice ObjectId;</code>
    <br><br>

    Beispiel:
    <ul>
      <code>define myDp BACnetDatapoint myBACnetDevice AV:10</code><br>
      <code></code><br>
    </ul>
  </ul>
  <br>

  <a name="BACnetDatapointset"></a>
  <b>Set</b>
  <ul>
    <code>set &lt;name&gt; &lt;Register_For_NCO&gt; &lt;64&gt;</code><br>
    Regsitriert sich bei der NCO 64 als Empfänger <br>
    Diese Set Befehle werden erst angezeigt, wenn die vorhandenen NCO ermittelt werden konnten <br>
    Hierfür den Befehl get notificationClasses ausführen.
  </ul>
  <br>

  <a name="BACnetDatapointget"></a>
  <b>Get</b> 
    <ul>
      <li><a href="#notificationClasses">notificationClasses</a><br>
      Liest alle vorhandenen NCO aus dem Device aus</li>
      <li><a href="#alarmSummary">alarmSummary</a><br>
      Liest alle anliegenden Meldungen aus dem Gerät aus und aktualisiert die entsprechenden Readings</li>

    </ul>
    <br>

  <a name="dummyattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a href="#disable">disable</a></li>
    <li><a href="#disabledForIntervals">disabledForIntervals</a></li>
    <li><a name="readingList">readingList</a><br>
      Leerzeichen getrennte Liste mit Readings, die mit "set" gesetzt werden
      k&ouml;nnen.</li>

    <li><a name="setList">setList</a><br>
      Liste mit Werten durch Leerzeichen getrennt. Diese Liste wird mit "set
      name ?" ausgegeben.  Damit kann das FHEMWEB-Frontend Auswahl-Men&uuml;s
      oder Schalter erzeugen.<br> Beispiel: attr dummyName setList on off </li>

    <li><a name="useSetExtensions">useSetExtensions</a><br>
      Falls gesetzt, und setList enth&auml;lt on und off, dann die <a
      href="#setExtensions">set extensions</a> Befehle sind auch aktiv.  In
      diesem Fall werden nur die Befehle aus setList und die set exensions
      akzeptiert.</li>

    <li><a href="#readingFnAttributes">readingFnAttributes</a></li>
  </ul>
  <br>

</ul>

=end html_DE

=cut
