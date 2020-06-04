##############################################
# $Id: 98_dummy.pm 16965 2018-07-09 07:59:58Z rudolfkoenig $
package main;

use strict;
use warnings;
use SetExtensions;

sub
BACnetDevice_Initialize($)
{
  my ($hash) = @_;

  $hash->{GetFn}     = "BACnetDevice_Get";
  $hash->{SetFn}     = "BACnetDevice_Set";
  $hash->{DefFn}     = "BACnetDevice_Define";
  $hash->{AttrList}  = "readingList " .
                       "disable disabledForIntervals " .
                       "notificationClasses notificationClassRegistrations covRegisterOnObjects " .
                       "registrationIntervall sendWhoIsIntervall useStaticBinding " .                       
                       $readingFnAttributes;  
}

###################################
sub
BACnetDevice_Get($$$)
{
  my ( $hash, $name, $opt, @args ) = @_;

	return "\"get $name\" needs at least one argument" unless(defined($opt));

  # CMD: Get Notification Classes
  if($opt eq "notificationClasses")
  {    
    readingsSingleUpdate($hash,"state", "CMD:Get Notification Classes",1);
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

  elsif($opt eq "clearObjectList")
  {    
    readingsSingleUpdate($hash,"objectList", "",1);
    return undef;
  }

  return "unknown argument choose one of notificationClasses:noArg alarmSummary:noArg objectList:noArg clearObjectList:noArg";
}

###################################
sub
BACnetDevice_Set($$)
{
  my ($hash, @a) = @_;
  my $name = shift @a;

  return "no set value specified" if(int(@a) < 1);
  
  my $cmd = shift @a;
  my @setList = ();

  # NCO:64 NCO:220
  my $devNcos = AttrVal($name,"notificationClasses",undef);
  if($devNcos) 
  {
    if($devNcos ne "no NCOs")
    {
      my @ncos = reverse(split ' ', $devNcos);
      my @ncoAvalilable = ();

      foreach my $nco (@ncos) {
        my ($ncoName, $ncoInstance) = split ':', $nco;
        # 64 96
        my @existing = split ' ', AttrVal($name,"notificationClassRegistrations", "");
        

        # mode:verbose,ultra,relaxed
        if ( not grep( /^$ncoInstance$/, @existing ) ) {
          # push @setList, "Register_For_NCO_$ncoInstance";
          push @ncoAvalilable, $ncoInstance;
        }        
      }

      if(int(@ncoAvalilable) > 0)
      {
        push @setList, "Register_For_NCO:" . join ',' , reverse @ncoAvalilable;
      }

    }
  }

  if($cmd =~ /Register_For_NCO/) {
    my $inco = shift @a;
    my $attrVal = AttrVal($name,"notificationClassRegistrations", "");
    my @existing = split ' ', $attrVal;
    
    # Prüfen ob NCO schon angegeben, wenn nicht dann zu dem Attribute hinzufügen
    if ( not grep( /^$inco$/, @existing ) ) {
      #readingsSingleUpdate($hash,"notificationClassesXXX", "Add",1);
      fhem("attr -a $name notificationClassRegistrations $inco");
      #push @existing, $inco;
    }
    else
    {
      #@existing = grep (!/^$inco$/), @existing;
      #my $idx = first { $existing[$_] eq '220' } 0..$#existing;
      #readingsSingleUpdate($hash,"notificationClassesXXX", "Delete " ,1);
      fhem("attr -r $name notificationClassRegistrations $inco");
      
      #delete @existing[$idx];
    }
    
    #fhem("attr $name notificationClassRegistrations " . join ' ', @existing);
    #$attr{$name}{notificationClassRegistrations} = join ' ', @existing;

    return undef;
  }

  if($cmd =~ /objectList/) {
    my $data = join ' ', @a;
    
    #$attr{$name}{BV} = $data;
    
    #my $error = setKeyValue($name . "_objectList", $data);
    
    #$hash->{ObjectList} = '<html><br><a href="http://192.168.123.52" target="_blank">192.168.123.52</a></html>' ;
    #readingsSingleUpdate($hash,"objectList", $data,1);

    return undef;
  }
  
  if($cmd eq "clearObjectList")
  {    
    readingsSingleUpdate($hash,"objectList", "",1);
    return undef;
  }
  
  
  #push @setList, "objectList:sortable,val1,val2";
  push @setList, "clearObjectList:noArg";

  return join ' ', @setList;
  
  return undef;
}

sub
BACnetDevice_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);
  

#  Log3 $hash, 1, "Get irgendwas " . join(" ", @{$a}) . " -> " . @{$a};
  return "Wrong syntax: use define <name> BACnetDevice BACnetNetwork DeviceIntance IP[:Port] [RouterIp:RouterPort]" if(int(@a) < 5);

  my $name = shift @a;
  my $type = shift @a;

  $attr{$name}{registrationIntervall} = 300 unless( AttrVal($name,"registrationIntervall",undef) );
   

  my $networkName = shift @a;
  my $instance = shift @a;
  my $ip = shift @a;
  
  if (index($ip, ':') == -1) {
    $ip .= ":47808";
  } 
  
  my $routerIp = shift @a;

  $hash->{IODev} = $networkName;
  $hash->{Instance} = $instance;
  $hash->{ObjectId} = "DEV:$instance";
  $hash->{IP} = $ip;

  $hash->{RouterIp} = $routerIp if($routerIp);
  
  if(AttrVal($name,"room",undef)) {
    
  } else {
    #$attr{$name}{room} = 'BACnet,BACnet->Devices->' . $instance;
    $attr{$name}{room} = 'BACnet,BACnet->Devices';
  }

  #my ($error, $value) = getKeyValue($name . "_objectList");
  #$hash->{ObjectList} = $value if($value);

  return undef;
}

1;

=pod
=item device
=item summary    BACnetDevice
=item summary_DE BACnetDevice Ger&auml;t

=begin html_DE
=begin html

<a name="BACnetDevice"></a>
<h3>BACnetDevice</h3>
<ul>

  Definiert eine BACnet Device Instanz
  <br><br>

  <a name="BACnetDevicedefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; BACnetDevice &lt;BACnetNetwork&gt; &lt;DeviceIntance&gt;</code>
    <br><br>

    Beispiel:
    <ul>
      <code>define myBACnetDevice myBACnetNetwork 1234 172.20.47.21[:47808]</code><br>
      <code>get notificationClasses</code><br>
    </ul>
  </ul>
  <br>

  <a name="BACnetDeviceset"></a>
  <b>Set</b>
  <ul>
  <li><a name="Register_For_NCO">Register_For_NCO</a><br>
      <p><code>set &lt;name&gt; &lt;Register_For_NCO&gt; &lt;64&gt;</code><br/>
        Registriert sich bei der NCO 64 als Empfänger <br>
        Die Set Befehle werden erst angezeigt, wenn die vorhandenen NCO ermittelt werden konnten <br>
        Hierfür den Befehl <code>get notificationClasses</code> ausführen.
      </p>
    </li>
  </ul>
  <br>

  <a name="BACnetDeviceget"></a>
  <p><b>Get</b> </p>
    <ul>      
      <li><a name="objectList">objectList</a><br>
          Liest alle im Gerät vorhandenen Datenpunkte aus und Erzeugt eine Tabelle im
          Reading ObjectList. Über diese Tabelle können Datenpunkte als 
          <a href="#BACnetDatapoint">BACnetDatapoint</a> erstellt werden.
      </li>
      <li>notificationClasses<br>            
          Liest alle vorhandenen NCO aus dem Device aus
      </li>
      <li><a name="alarmSummary">alarmSummary</a><br>      
        Liest alle anliegenden Meldungen aus dem Gerät aus und aktualisiert
        die entsprechenden Readings
      </li>
      <li><a name="clearObjectList">clearObjectList</a><br>      
        Löscht die Tabelle im Reading "objectList".
      </li>

    </ul>
    <br>

  <a name="BACnetDeviceattr"></a>
  <b>Attributes</b>
  <ul>
    <li><a name="notificationClasses">notificationClasses</a><br>
      Leerzeichen getrennte Liste mit den im Device vorhandenen NotificationClasses.<br/>
      Die vorhandenen NCO können mittels "get notificationClasses" aus dem Gerät ermittelt werden.<br/>
      Sobald NCO vorhanden sind, können diese mittles "set Register_For_NCO xxx" gesetzt werden
    </li>
    <li><a name="notificationClassRegistrations">notificationClassRegistrations</a><br>
      Leerzeichen getrennte Liste mit den NotificationClasse Instanznummern, bei welchen sich das Netzwerk als Empfänger registrieren soll.<br/>
      Die Einträge können über "set Register_For_NCO xxx" gesetzt werden.<br/>
      Der Status der jeweiligen Registrierung kann dem Reading ncoRegState_XX entnommen werden. XX entspricht dabei der Instanznummer der NCO.
    </li>
    <li><a name="registrationIntervall">registrationIntervall</a><br>
      Intervall in sekunden in dem sich das Netzwerk als Empfänger
      bei den unter notificationClassRegistrations NCO registrieren soll.<br/>
      Der Status der jeweiligen Registrierung kann dem Reading ncoRegState_XX entnommen werden. XX entspricht dabei der Instanznummer der NCO.
    </li>
    <li><a name="sendWhoIsIntervall">sendWhoIsIntervall</a><br>
      Intervall in sekunden in dem das Netzwerk ein dediziertes WhoIs an das Gerät sendet.
      Dieses WhoIs wird nur versendet, wenn das Gerät Offline ist / war.<br/>
      Der Status der kann dem Reading lastsendWhoIsIntervallTime entnommen werden.
    </li>
    <li><a name="useStaticBinding">useStaticBinding</a><br>
      Wird dieses Attribute auf 1 gesetzt, so wird versucht das Gerät ohne IAM Bestätigung zu erreichen. <br/>
      Diese Funktion ist Sinnvoll, wenn die Geräte nicht auf Broadcast Nachtichten antworten können z.B.: in VPN Netwerken.
    </li>
    <li><a href="#disable">disable</a></li>
    <li><a href="#disabledForIntervals">disabledForIntervals</a></li>


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

=end html
=end html_DE

=cut
