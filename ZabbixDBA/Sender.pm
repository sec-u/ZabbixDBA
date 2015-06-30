package ZabbixDBA::Sender;

use 5.010;
use strict;
use warnings;
use English qw(-no_match_vars);
use Carp qw(confess carp);

our $VERSION = 1.010;

use IO::Socket::INET;
use MIME::Base64 qw(encode_base64);

my $data_template = <<'EOF';
<req>
<host>%s</host>
<key>%s</key>
<data>%s</data>
</req>
EOF

sub new {
    my ( $class, %server_list ) = @_;
    my $self = \%server_list;
    return bless $self, $class;
}

sub encode {
    chomp( my $result = encode_base64(shift) );
    return $result;
}

sub send {
    my ( $self, @data ) = @_;
    for my $sever ( values %{$self} ) {
        for (@data) {
            my $socket = IO::Socket::INET->new(
                PeerHost => $sever->{address},
                PeerPort => $sever->{port},
                Proto    => 'tcp',
            );

            if ( !$socket ) {
                confess sprintf
                    'Unable to connect to Zabbix server: %s:%d',
                    $sever->{address},
                    $sever->{port};
            }

            my ( $host, $key, $data ) = @{$_};
            my $data_base64 = sprintf $data_template,
                encode($host),
                encode($key),
                encode($data);
            $socket->send($data_base64);
            printf "%s::%s => %s\n", $host, $key, $data;
            $socket->close();
        }
    }
    return 1;
}

1;
