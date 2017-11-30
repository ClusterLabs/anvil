#!/usr/bin/perl

use Device::SerialPort;

my @baud_rates = (9600, 115200);

sub find_serial_devices
{
  my $dev_path = "/dev";
  my @devices;
  local(*DIRECTORY);
  opendir(DIRECTORY, $dev_path);
  while(my $file = readdir(DIRECTORY))
  {
    if ($file =~ /ttyUSB.*/)
    {
      my $path = $dev_path . "/$file";
      push @devices, $path;
      #print "Device found: $path\n\n";
    }
  }
  print "Testing Serial Devices...\n\n";
  test_serial_devices({devices => \@devices});
}

sub test_serial_devices
{
  my $parameter = shift;
  my @successful_devices;
  my $devices = defined $parameter->{devices} ? $parameter->{devices} : ();

  foreach my $device (@{$devices})
  {
    foreach my $baud_rate (@baud_rates)
    {
      my $device_test = {device => $device, baud_rate => $baud_rate};
      if (test_serial_device($device_test))
      {
        print "Device Found: $device, Baud Rate: $baud_rate\n\n";
        push @successful_devices, $device_test;
        last;
      }
      sleep(2);
    }
  }
}

sub test_serial_device
{
  my $parameter = shift;
  my $device = defined $parameter->{device} ? $parameter->{device} : "";

  my $baud_rate = defined $parameter->{baud_rate} ? $parameter->{baud_rate} : "";
  my $port = new Device::SerialPort($device, 1) || return 0;
  $port->baudrate($baud_rate);
  $port->parity("none");
  $port->databits(8);
  $port->stopbits(1);
  $port->write("\r");
  $port->lookclear();
  sleep(2);
  my $output = $port->read(256);
  $port->close();
  #print "Testing Device: $device, Baud Rate: $baud_rate\n";
  #print "Output: $output\n\n";
  return ($output =~ /(?=.*[ -~])[ -~]{5,}.*$/);
}

find_serial_devices();
